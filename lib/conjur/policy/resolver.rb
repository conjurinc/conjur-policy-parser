module Conjur
  module Policy
    class Resolver
      attr_reader :account, :ownerid, :namespace
      
      class << self
        # Resolve records to the specified owner id and namespace.
        def resolve records, account, ownerid, namespace = nil
          resolver_classes = [ AccountResolver, IdSubstitutionResolver, AnnotationSubstitutionResolver, OwnerResolver, FlattenResolver, DuplicateResolver ]
          resolver_classes.each do |cls|
            resolver = cls.new account, ownerid, namespace
            records = resolver.resolve records
          end
          records
        end
      end
      
      # +account+ is required. It's the default account whenever no account is specified.
      # +ownerid+ is required. Any records without an owner will be assigned this owner. The exception
      # is records defined in a policy, which are always owned by the policy role unless an explicit owner
      # is indicated (which would be rare).
      # +namespace+ is optional. It's prepended to the id of every record, except for ids which begin
      # with a '/' character.
      def initialize account, ownerid, namespace = nil
        @account = account
        @ownerid   = ownerid
        @namespace = namespace
        
        raise "account is required" unless account
        raise "ownerid is required" unless ownerid
        raise "ownerid must be fully qualified account, kind and identifier" unless ownerid.to_s.split(":", 3).length == 3
      end
      
      protected
      
      # Traverse an Array-ish of records, calling a +handler+ method for each one.
      # If a record is a Policy, then the +policy_handler+ is invoked, after the +handler+.
      def traverse records, visited, handler, policy_handler = nil
        Array(records).flatten.each do |record|
          next unless visited.add?(id_of(record))

          handler.call record, visited
          policy_handler.call record, visited if policy_handler && record.is_a?(Types::Policy)
        end
      end
      
      def id_of record
        record.object_id
      end
    end
    
    # Updates all nil +account+ fields to the default account.
    class AccountResolver < Resolver
      def resolve records
        traverse records, Set.new, method(:resolve_account), method(:on_resolve_policy)
      end
      
      def resolve_account record, visited
        if record.respond_to?(:account) && record.respond_to?(:account=) && record.account.nil?
          record.account = @account
        end
        traverse record.referenced_records, visited, method(:resolve_account), method(:on_resolve_policy)
      end
      
      def on_resolve_policy policy, visited
        traverse policy.body, visited, method(:resolve_account), method(:on_resolve_policy)
      end
    end

    class SubstitutionResolver < Resolver
      SUBSTITUTIONS = { "$namespace" => :namespace }
        
      def resolve records
        traverse records, Set.new, method(:resolve_field), method(:on_resolve_policy)
      end
      
      protected
      
      def substitute! id
        SUBSTITUTIONS.each do |k,v|
          next unless value = send(v)
          id.gsub! k, value
        end
      end
      
      def on_resolve_policy policy, visited
        saved_namespace = @namespace
        @namespace = policy.id
        traverse policy.body, visited, method(:resolve_field), method(:on_resolve_policy)
      ensure
        @namespace = saved_namespace
      end
    end
    
    # Makes all ids absolute, by prepending the namespace (if any) and the enclosing policy (if any).
    class IdSubstitutionResolver < SubstitutionResolver
      
      def resolve_field record, visited
        if record.respond_to?(:id) && record.respond_to?(:id=)
          record.id = substitute_id record
        end
        
        traverse record.referenced_records, visited, method(:resolve_field), method(:on_resolve_policy)
      end
      
      protected

      def substitute_id record
        id = record.id
        if id.blank?
          raise "#{record.class.simple_name} has no id" unless namespace
          id = namespace
        elsif id == '/'
          # pass
        elsif id[0] == '/'
          id = id[1..-1]
        else
          if record.respond_to?(:resource_kind) && record.resource_kind == "user"
            id = [ id, user_namespace ].compact.join('@')
          else
            id = [ namespace, id ].compact.join('/')
          end
        end

        substitute! id

        id
      end

      
      def user_namespace
        namespace.gsub('/', '-') if namespace
      end
    end
    
    class AnnotationSubstitutionResolver < SubstitutionResolver
      def resolve_field record, visited
        if record.respond_to?(:annotations) && (annotations = record.annotations)
          annotations.each do |k,v|
            substitute! v
          end
        end

        traverse record.referenced_records, visited, method(:resolve_field), method(:on_resolve_policy)
      end
    end
    
    # Sets the owner field for any records which support it, and don't have an owner specified.
    # Within a policy, the default owner is the policy role. For global records, the 
    # default owner is the +ownerid+ specified in the constructor.
    class OwnerResolver < Resolver
      def resolve records
        traverse records, Set.new, method(:resolve_owner), method(:on_resolve_policy)
      end
      
      def resolve_owner record, visited
        if record.respond_to?(:owner) && record.owner.nil?
          record.owner = Types::Role.new(@ownerid)
        end
      end
      
      def on_resolve_policy policy, visited
        saved_ownerid = @ownerid
        @ownerid = [ policy.account, "policy", policy.id ].join(":")
        traverse policy.body, visited, method(:resolve_owner), method(:on_resolve_policy)
      ensure
        @ownerid = saved_ownerid
      end
    end
    
    # Flattens and sorts all records into a single list, including YAML lists and policy body.
    class FlattenResolver < Resolver
      def resolve records
        @result = []
        traverse records, Set.new, method(:resolve_record), method(:on_resolve_policy)

        # Sort record creation before anything else.
        # Sort record creation in dependency order (if A owns B, then A will be created before B).
        # Otherwise, preserve the existing order.

        @stable_index = {}
        @result.each_with_index do |obj, idx|
          @stable_index[obj] = idx
        end
        @referenced_record_index = {}
        @result.each_with_index do |obj, idx|
          @referenced_record_index[obj] = obj.referenced_records.select{|r| r.respond_to?(:roleid)}.map(&:roleid)
        end
        @result.flatten.sort do |a,b|
          score = sort_score(a) - sort_score(b)
          if score == 0
            if a.respond_to?(:roleid) && @referenced_record_index[b].member?(a.roleid) &&
              b.respond_to?(:roleid) && @referenced_record_index[a].member?(b.roleid)
              raise "Dependency cycle encountered between #{a} and #{b}"
            elsif a.respond_to?(:roleid) && @referenced_record_index[b].member?(a.roleid)
              score = -1
            elsif b.respond_to?(:roleid) && @referenced_record_index[a].member?(b.roleid)
              score = 1
            else
              score = @stable_index[a] - @stable_index[b]
            end
          end
          score
        end
      end
      
      protected
      
      # Sort "Create" and "Record" objects to the front.
      def sort_score record
        if record.is_a?(Types::Record)
          -1
        else
          0
        end
      end
      
      # Add the record to the result.
      def resolve_record record, visited
        @result += Array(record)
      end

      # Recurse on the policy body records.
      def on_resolve_policy policy, visited
        body = policy.body
        policy.remove_instance_variable "@body"
        traverse body, visited, method(:resolve_record), method(:on_resolve_policy)
      end
    end
    
    # Raises an exception if the same record is declared more than once.
    class DuplicateResolver < Resolver
      def resolve records
        seen = Set.new
        Array(records).flatten.each do |record|
          if record.respond_to?(:id) && !seen.add?([ record.class.short_name, record.id ])
            raise "#{record} is declared more than once"
          end
        end
      end
    end
    
    # Unsets attributes that make for more verbose YAML output. This class is used to 
    # compact YAML expectations in test cases. It expects pre-flattened input.
    #
    # +account+ attributes which match the provided account are set to nil.
    # +owner+ attributes which match the provided ownerid are removed.
    class CompactOutputResolver < Resolver
      def resolve records
        traverse records, Set.new, method(:resolve_owner)
        traverse records, Set.new, method(:resolve_account)
      end
      
      def resolve_account record, visited
        if record.respond_to?(:account) && record.respond_to?(:account=) && record.account && record.account == self.account
          record.remove_instance_variable :@account
        end
        traverse record.referenced_records, visited, method(:resolve_account)
      end

      def resolve_owner record, visited
        if record.respond_to?(:owner) && record.respond_to?(:owner=) && record.owner && record.owner.roleid == self.ownerid
          record.remove_instance_variable :@owner
        end
        traverse record.referenced_records, visited, method(:resolve_owner)
      end
    end
  end
end

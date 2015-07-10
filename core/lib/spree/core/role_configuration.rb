require 'singleton'

module Spree
  # A class responsible for associating {Spree::Role} with a list of permission sets.
  #
  # @see Spree::PermissionSets
  #
  # @example Adding order, product, and user display to customer service users.
  #   Spree::RoleConfiguration.configure do |config|
  #     config.register_role :customer_service, [
  #       Spree::PermissionSets::OrderDisplay,
  #       Spree::PermissionSets::UserDisplay,
  #       Spree::PermissionSets::ProductDisplay
  #     ]
  #   end
  class RoleConfiguration
    # An internal structure for the association between a role and a
    # set of permissions.
    Role = Struct.new(:name, :permission_sets)

    include Singleton
    attr_accessor :roles

    # Yields the instance of the singleton, used for configuration
    # @yield_param instance [Spree::RoleConfiguration]
    def self.configure
      yield(instance)
    end

    # Given an ability, and a user, determine what permissions sets can be activated
    # on the ability, then activate them.
    #
    # This performs can/cannot declarations on the ability, and can modify it's internal permissions
    #
    # @param ability [CanCan::Ability] the ability to invoke declarations on
    # @param user [#spree_roles] the user that holds the spree_roles association.
    def activate_permissions! ability, user
      spree_roles = user.spree_roles.pluck(:name)
      applicable_permissions = Set.new

      spree_roles.each do |role_name|
        if roles.key?(role_name)
          applicable_permissions |= roles[role_name].permission_sets
        end
      end

      applicable_permissions.each do |permission_set|
        permission_set.new(ability).activate!
      end
    end

    # Not public due to the fact this class is a Singleton
    # @!visibility private
    def initialize
      @roles = Hash.new do |h, name|
        h[name] = Role.new(name, Set.new)
      end
    end

    # Assign permission sets for a {Spree::Role} that has the name of role_name
    # @param role_name [Symbol, String] The name of the role to associate permissions with
    # @param permission_sets [Array<Spree::PermissionSets::Base>, Set<Spree::PermissionSets::Base>]
    #   A list of permission sets to activate if the user has the role indicated by role_name
    def assign_permissions role_name, permission_sets
      name = role_name.to_s

      roles[name].permission_sets |= permission_sets
      roles[name]
    end
  end
end
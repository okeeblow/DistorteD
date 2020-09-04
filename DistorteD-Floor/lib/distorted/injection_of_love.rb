module Cooltrainer; end
module Cooltrainer::DistorteD; end
module Cooltrainer::DistorteD::InjectionOfLove


  # Only touch certain attributes so we aren't entirely rude.
  DISTORTED_CONSTANTS = Set[
    :LOWER_WORLD,
    :OUTER_LIMITS,
    :ATTRS,
    :ATTRS_DEFAULT,
    :ATTRS_VALUES,
  ]


  # Multiple-data-structure handler for DistorteD attribute combination.
  def self.combine(to, from)
    if from.respond_to?(:merge) and to.respond_to?(:merge)
      # Set and Hash :merge — duplicate keys will be overwritten.
      to.merge(from)
    elsif from.respond_to?(:concat) and to.respond_to?(:concat)
      # Array uses concat — duplicates stay duplicate.
      to.concat(from)
    else
      # I don't currently use anything for an attribute in any MediaMolecule
      # that would fall back to this, but I wanted to have some sort of
      # `else` here lol.
      # Relies on :to implementing :<<, but most things seem to.
      from.each{|i| to << i}
    end
    to
  end

  # Returns a block that performs the DistorteD attribute constant merge.
  MrConstant = Proc.new { |from, to, inherit: false, invite: true|
    # Merge any attributes defined in our including scope /!\ *prior* to our inclusion /!\.
    # It's kind of silly to put these together and then split them back
    # apart again with :const_defined?, but the alternative is calling
    # this twice to handle the case of :from into :from's own
    # singleton_class. That might seem even sillier, but that allows
    # callers to only need to look in one place and easily handle
    # items defined in the same layer as the caller, e.g. media-type
    # rendering methods defined in the Jekyll layer being used in the
    # Jekyll layer.
    (
      (from.constants(inherit).to_set & DISTORTED_CONSTANTS) |
      (from.singleton_class.constants(inherit).to_set & DISTORTED_CONSTANTS)
    ).each { |invitation|
      ours = from.const_get(invitation)
      theirs = ours.dup
      # There's some redundancy here with Bundler's const_get_safely:
      # https://ruby-doc.org/stdlib/libdoc/bundler/rdoc/Bundler/SharedHelpers.html#method-i-const_get_safely
      #
      # …but even though I use and enjoy using Bundler it feels Wrong™ to me to have
      # that method in stdlib and especially in Core but not as part of Module since
      # 'Bundler' still feels like a third-party namespace to me v(._. )v
      if to.singleton_class.const_defined?(invitation, false)
        self.combine(theirs, to.singleton_class.const_get(invitation))
        to.singleton_class.send(:remove_const, invitation)
      elsif to.class.const_defined?(invitation, false)
        theirs = ours.dup
        self.combine(theirs, to.class.const_get(invitation))
      end
      to.singleton_class.const_set(invitation, theirs)
    }  # from.constants.each

    # Define methods in the including context to perpetuate the merging process :)
    # Avoid multiple injections to the same ancestry by leaving a receipt.
    if invite and not to.singleton_methods(false).include?(:invitation_from_mr_constant)
      to.define_singleton_method(:append_features) do |otra|
        Cooltrainer::DistorteD::InjectionOfLove::AfterParty.call(otra)
        Cooltrainer::DistorteD::InjectionOfLove::Invitation.call(otra)
        super(otra)
      end
      to.define_singleton_method(:prepend_features) do |otra|
        Cooltrainer::DistorteD::InjectionOfLove::AfterParty.call(otra)
        Cooltrainer::DistorteD::InjectionOfLove::Invitation.call(otra)
        super(otra)
      end
      to.define_singleton_method(:extend_object) do |otra|
        Cooltrainer::DistorteD::InjectionOfLove::AfterParty.call(otra)
        Cooltrainer::DistorteD::InjectionOfLove::Invitation.call(otra)
        super(otra)
      end
      to.define_singleton_method(:invitation_from_mr_constant) do
        from.name
      end
    end
  }

  # Returns a block that will define methods in a given context
  # such that when the given context is included/extended/prepended
  # we will first merge our DD attributes into the new layer,
  # then calling :super on the new layer to resume the
  # include/extend/prepend process (/!\ important /!\ lol).
  # The entire stack of attributes would still be accessible in
  # any layer by chaining :super there, but I want to merge them.
  Invitation = Proc.new { |otra|
    otra.define_singleton_method(:append_features) do |winter|
      Cooltrainer::DistorteD::InjectionOfLove::MrConstant.call(otra, winter)
      super(winter)
    end
    otra.define_singleton_method(:prepend_features) do |winter|
      Cooltrainer::DistorteD::InjectionOfLove::MrConstant.call(otra, winter)
      super(winter)
    end
    otra.define_singleton_method(:extend_object) do |winter|
      Cooltrainer::DistorteD::InjectionOfLove::MrConstant.call(otra, winter)
      super(winter)
    end
  }

  # Returns a block that will merge DistorteD attributes from a given context
  # and its included_modules into its singleton_class.
  AfterParty = Proc.new { |otra|
    # The including context may have included other modules before us,
    # and those modules may have constants we care about.
    # Descend into any included modules besides ourself.
    # :included_modules is automatically recursive downward, e.g. includes the
    # :included_modules of all of :otra's :included_modules, and theirs,
    # and theirs, etc.
    # Also include :otra itself here so callers only need to look
    # at the singleton_class and can trust they got everything.
    ((Set[otra] | otra.included_modules.to_set | otra.singleton_class.included_modules) - Set[self]).each do |mod|
      unless mod.singleton_class.respond_to?(:invitation_from_mr_constant)
        Cooltrainer::DistorteD::InjectionOfLove::MrConstant.call(mod, otra, invite: false)
      end
    end
  }

  # Activate this module when it's included.
  # We will merge DistorteD attributes to the singleton class from
  # our including context and from out including context's included_modules,
  # then we will define methods in the including context to perpetuate
  # the merging process when that context is included/extended/prepended.
  def self.included(otra)
    self::AfterParty.call(otra)
    self::Invitation.call(otra)
    super
  end

end

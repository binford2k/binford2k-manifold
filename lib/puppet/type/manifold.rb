Puppet::Type.newtype(:manifold) do
  desc <<-'ENDOFDESC'
  A manifold is like an anchor, but used for defining multiple relationships,
  the way we used to use collectors before we realized how dangerous they were.

  For example:

      manifold { 'internal':
        type         => 'package',
        match        => 'tag',
        pattern      => 'internal',
        relationship => before,
      }

      package { ['foo', 'bar', 'baz']:
        ensure  => present,
        tag     => 'internal',
      }

      yumrepo { 'internal':
        ensure   => 'present',
        baseurl  => 'file:///var/yum/mirror/centos/7/os/x86_64',
        descr    => 'Locally stored packages',
        enabled  => '1',
        gpgcheck => '0',
        priority => '10',
        before   => Manifold['internal'],
      }

  ENDOFDESC


  newparam(:type, :namevar => true) do
    desc 'The type of other resource to depend upon'

    munge do |value|
      value.to_s.downcase.to_sym
    end

    validate do |value|
      unless Puppet::Type.type(value)
        fail Puppet::ParseError, "'#{value}' is not the name of a resource type."
      end
    end
  end

  newparam(:match) do
    desc 'The parameter name to match on'

    munge do |value|
      value.to_s.downcase.to_sym
    end
  end

  newparam(:pattern) do
    desc 'A string or regex pattern to match in combination with the match param'

    munge do |value|
      if value[0] == '/' and value[-1] == '/'
        Regexp.new(value[1...-1])
      else
        value
      end
    end

    validate do |value|
      unless [String, Regexp].include?(value.class)
        fail Puppet::ParseError, "Pattern must be a string or regex '#{value}'"
      end
    end
  end

  newparam(:invert) do
    desc 'Invert the pattern matching.'
    newvalues(:true, :false)
    defaultto :false

    munge do |value|
      [true, :true].include? value
    end
  end

  newparam(:relationship) do
    munge do |value|
      value.to_s.downcase.to_sym
    end

    desc 'The relationship to enforce from this resource to the matched resources'
    validate do |value|
      unless [:before, :require, :subscribe, :notify].include?(value.to_sym)
        fail Puppet::ParseError, "'#{value}' is not a valid relationship"
      end
    end
  end

  # TODO
  newparam(:query) do
    desc 'A hash of matches and patterns to use'
  end

  validate do
    [:match, :pattern, :relationship].each do |param|
      if not self.parameters[param]
        self.fail "Required parameter missing: #{param}"
      end
    end

    unless self[:match] == :title or Puppet::Type.type(self[:type]).valid_parameter? self[:match]
       fail Puppet::ParseError, "The #{self[:type]} type does not have a param of '#{self[:match]}'"
    end
  end

  # OK, this is where it gets gross. Instead of using the new fancy auto* implicit relationship
  # builders, we use the old autorequire and just force our relationships into the catalog. The
  # reason for this is that we want to be able to match based on a pattern, and very old Puppet
  # doesn't have the other auto relationships anyway.
  def autorequire(rel_catalog = nil)
    rel_catalog ||= catalog
    raise(Puppet::DevError, "You cannot add relationship without a catalog") unless rel_catalog

    # TODO: this will only work with native types!
    klass = Puppet::Type.type(self[:type])
    reqs  = super

    rel_catalog.resources.select{|x| x.class == klass}.each do |res|
      next unless match(res, self[:match], self[:pattern], self[:invert])

      res.refresh if [:subscribe, :notify].include? self[:relationship]

      case self[:relationship]
      when :before, :subscribe
        reqs << Puppet::Relationship::new(self, res)

      when :require, :notify
        reqs << Puppet::Relationship::new(res, self)

      end
    end
    reqs
  end

  # TODO: not sure I like this logic, but I can revisit later
  def match(res, match, pattern, invert = false)
    param = (match == :title) ? res[:name] : res[match]
    param = Array(param) # coerce to an array, because it simplifies some logic

    case pattern
    when String
      found = param.include? pattern
    when Regexp
      found = ! (param.grep pattern).empty?
    end

    invert ? !match : match
  end

  def refresh
    # We don't do anything with them, but we need this to
    #   show that we are "refresh aware" and not break the
    #   chain of propagation.
  end
end

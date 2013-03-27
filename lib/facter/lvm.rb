# Author: Markus Strauss <Markus@ITstrauss.eu>

require 'facter'

def lvm_volumes
  if File.exist?('/sbin/lvs')
    `/sbin/lvs --noheadings --nosuffix -o name 2> /dev/null`.split
  end
end

Facter.add('lvm_volumes') do
  confine :kernel => :linux
  setcode do
    lvm_volumes.join ','
  end
end

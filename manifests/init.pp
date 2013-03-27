class lvm{
  
  # deprecated: please use lvm::diskvolume instead
  class simplevolume( $name, $device, $mountpoint, $fs = 'ext3', $group = 'data' ) {
    notice( "lvm::simplevolume is deprecated; use lvm::diskvolume instead.")
    lvm::device{ $device: }
    lvm::group { $group: devices => $device }
    lvm::volume{ $name:
      group      => $group,
      extents    => '100%FREE',
      fs         => $fs,
      mkfs       => true,
      mountpoint => $mountpoint,
    }
  }
  
  # title => device name, like '/dev/sdb'
  define device() {
    exec { "pvcreate-${name}":
      unless  => "pvs | grep '${title}\\b'",
      command => "pvcreate -vZy ${title}",
    }
  }
  
  # devices => array of device names, or a single device name string
  define group( $devices ) {
    $_devices = join($devices)
    exec { "vgcreate-${name}":
      unless  => "vgs | grep ${title}",
      command => "vgcreate -v ${title} ${_devices}",
      require => Lvm::Device[$devices],
    }
  }
  
  define volume( $group, $extents, $fs = nil, $mountpoint = nil, $mkfs = false ) {
    
    if $group {
      $_device = "/dev/mapper/${group}-${name}"
      
      exec { "lvcreate-$name":
        unless  => "test -b ${_device}",
        command => "lvcreate $group -n $name -l$extents",
        require => Lvm::Group[$group],
        notify  => Exec["mkfs-$name"],
      }
      
      if $fs and $mkfs {
        exec { "mkfs-${name}":
          refreshonly => true,
          command     => "mkfs.$fs -v -L ${name} ${_device}",
        }
      } else {
        exec { "mkfs-${name}":
          refreshonly => true,
          command     => "true",
        }
      }
      
      if $fs and $mountpoint != nil {
        $file = "/etc/fstab"
        editfile{ "${name}_fstab":
          path    => $file,
          match   => "%r[^${_device}\\s|\\s${mountpoint}\\s]",
          ensure  => "${_device} ${mountpoint} ${fs} defaults 1 2",
          require => Exec["lvcreate-${name}"],
          notify  => Exec["mount ${_device}"],
        }
        
        if !defined( File[$file] ) {
          file{ $file: }
        }
        exec{ "create directory ${mountpoint}":
          command => "mkdir -p $mountpoint",
          unless  => "test -d $mountpoint",
        }
        exec{ "mount ${_device}":
          require => [
            Exec["create directory ${mountpoint}"],
            Editfile["${name}_fstab"],
            Exec["mkfs-${name}"],
          ],
          # first test: TRUE (retval=0) if the directory exists
          # second test: TRUE (retval=0) if the directory is empty
          # only when BOTH are true, we do mount
          onlyif  => "test -d ${mountpoint} && test $( find '${mountpoint}' -type f | wc -l ) -eq 0",
          # and it may not be mounted alread, o'course
          unless  => "mount |grep '${_device}\\b'"
        }
        
      }
      
    } else {
      # no group
      err( "You must provide a LVM group name." )
    }
    
  }
  
}

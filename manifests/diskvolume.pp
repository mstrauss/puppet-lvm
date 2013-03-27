define lvm::diskvolume( $device, $mountpoint, $fs = 'ext3', $group = "vg_${name}" ) {
  
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

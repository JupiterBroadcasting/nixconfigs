# Home Assistant OS VM configuration
# Runs HAOS in KVM/libvirt with bridged networking
{
  config,
  pkgs,
  lib,
  ...
}: let
  # VM configuration
  vmName = "haos";
  diskPath = "/path/to/images/haos_ova-16.3.qcow2";
  bridgeName = "br0";

  # OVMF paths
  ovmfCode = "${pkgs.OVMFFull.fd}/FV/OVMF_CODE.fd";
  ovmfVars = "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.fd";

  # Libvirt XML definition for HAOS VM
  haosXml = pkgs.writeText "haos.xml" ''
    <domain type='kvm'>
      <name>${vmName}</name>
      <uuid>a1b2c3d4-e5f6-7890-abcd-ef1234567890</uuid>
      <memory unit='GiB'>8</memory>
      <currentMemory unit='GiB'>8</currentMemory>
      <vcpu placement='static'>2</vcpu>
      <os>
        <type arch='x86_64' machine='q35'>hvm</type>
        <loader readonly='yes' type='pflash'>${ovmfCode}</loader>
        <nvram template='${ovmfVars}'>/var/lib/libvirt/qemu/nvram/${vmName}_VARS.fd</nvram>
        <boot dev='hd'/>
      </os>
      <features>
        <acpi/>
        <apic/>
      </features>
      <cpu mode='host-passthrough' check='none' migratable='on'/>
      <clock offset='utc'>
        <timer name='rtc' tickpolicy='catchup'/>
        <timer name='pit' tickpolicy='delay'/>
        <timer name='hpet' present='no'/>
      </clock>
      <on_poweroff>destroy</on_poweroff>
      <on_reboot>restart</on_reboot>
      <on_crash>destroy</on_crash>
      <devices>
        <emulator>${pkgs.qemu_kvm}/bin/qemu-system-x86_64</emulator>
        <disk type='file' device='disk'>
          <driver name='qemu' type='qcow2' discard='unmap'/>
          <source file='${diskPath}'/>
          <target dev='vda' bus='virtio'/>
          <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>
        </disk>
        <interface type='bridge'>
          <source bridge='${bridgeName}'/>
          <model type='virtio'/>
          <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
        </interface>
        <serial type='pty'>
          <target type='isa-serial' port='0'>
            <model name='isa-serial'/>
          </target>
        </serial>
        <console type='pty'>
          <target type='serial' port='0'/>
        </console>
        <input type='tablet' bus='usb'>
          <address type='usb' bus='0' port='1'/>
        </input>
        <input type='mouse' bus='ps2'/>
        <input type='keyboard' bus='ps2'/>
        <memballoon model='virtio'>
          <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
        </memballoon>
        <rng model='virtio'>
          <backend model='random'>/dev/urandom</backend>
          <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>
        </rng>
        <controller type='usb' index='0' model='qemu-xhci'>
          <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x0'/>
        </controller>
        <controller type='pci' index='0' model='pcie-root'/>
        <controller type='pci' index='1' model='pcie-root-port'>
          <model name='pcie-root-port'/>
          <target chassis='1' port='0x10'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0' multifunction='on'/>
        </controller>
        <controller type='pci' index='2' model='pcie-root-port'>
          <model name='pcie-root-port'/>
          <target chassis='2' port='0x11'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x1'/>
        </controller>
        <controller type='pci' index='3' model='pcie-root-port'>
          <model name='pcie-root-port'/>
          <target chassis='3' port='0x12'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x2'/>
        </controller>
        <controller type='pci' index='4' model='pcie-root-port'>
          <model name='pcie-root-port'/>
          <target chassis='4' port='0x13'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x3'/>
        </controller>
        <controller type='pci' index='5' model='pcie-root-port'>
          <model name='pcie-root-port'/>
          <target chassis='5' port='0x14'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x4'/>
        </controller>
        <controller type='pci' index='6' model='pcie-root-port'>
          <model name='pcie-root-port'/>
          <target chassis='6' port='0x15'/>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x5'/>
        </controller>
        <controller type='sata' index='0'>
          <address type='pci' domain='0x0000' bus='0x00' slot='0x1f' function='0x2'/>
        </controller>
        <!-- ZigBee dongle: Silicon Labs CP210x -->
        <hostdev mode='subsystem' type='usb' managed='yes'>
          <source>
            <vendor id='0x10c4'/>
            <product id='0xea60'/>
          </source>
        </hostdev>
      </devices>
    </domain>
  '';
in {
  # ===========================================
  # LIBVIRT / KVM
  # ===========================================

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
    };
  };

  # Add user to libvirt group
  users.users.admin.extraGroups = ["libvirtd"];

  # Useful tools for VM management
  environment.systemPackages = with pkgs; [
    virt-manager # GUI (can use remotely via X forwarding)
    virt-viewer
    libguestfs # Disk image tools
  ];

  # ===========================================
  # HAOS VM AUTO-START
  # ===========================================
  # Systemd service to define and start the HAOS VM
  # This runs after libvirtd is ready

  systemd.services.haos-vm = {
    description = "Home Assistant OS VM";
    after = ["libvirtd.service" "network-online.target"];
    wants = ["network-online.target"];
    requires = ["libvirtd.service"];
    wantedBy = ["multi-user.target"];

    path = [pkgs.libvirt];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      # Wait for libvirt socket
      while [ ! -S /var/run/libvirt/libvirt-sock ]; do
        sleep 1
      done

      # Check if VM is already defined
      if ! virsh dominfo ${vmName} &>/dev/null; then
        echo "Defining HAOS VM..."
        virsh define ${haosXml}
      fi

      # Start VM if not running
      if ! virsh domstate ${vmName} | grep -q "running"; then
        echo "Starting HAOS VM..."
        virsh start ${vmName}
      fi
    '';

    preStop = ''
      # Graceful shutdown on service stop
      if virsh domstate ${vmName} | grep -q "running"; then
        echo "Shutting down HAOS VM..."
        virsh shutdown ${vmName}
        # Wait up to 60 seconds for graceful shutdown
        for i in $(seq 1 60); do
          if ! virsh domstate ${vmName} | grep -q "running"; then
            break
          fi
          sleep 1
        done
        # Force off if still running
        if virsh domstate ${vmName} | grep -q "running"; then
          virsh destroy ${vmName}
        fi
      fi
    '';
  };
}

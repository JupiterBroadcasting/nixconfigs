# Linux Unplugged Episode 650 Clinic Config

This is the clinic configuration from [Linux Unplugged Episode 650](https://linuxunplugged.com/650). A complete NixOS setup that turns a mini PC into a home router with integrated Home Assistant OS.

## What's Included

- NAT router with nftables firewall
- DHCP and DNS via dnsmasq
- Home Assistant OS running in a KVM virtual machine
- Nebula VPN for remote access
- ZigBee USB passthrough to Home Assistant

## Hardware Requirements

- Intel CPU with VT-x support
- 16GB RAM (8GB for VM, 8GB for host)
- Two network interfaces (or USB Ethernet adapter)
- ZigBee USB dongle (optional, for smart home devices)

## Network Layout

- **WAN**: Gets DHCP from upstream (default: `enp0s20f0u6`)
- **LAN**: `192.168.3.1/24` on bridge `br0` (default: `enp1s0`)
- **Home Assistant**: `192.168.3.230`
- **Nebula VPN**: `192.168.100.x` overlay network

## Customizing

You'll need to update these for your environment:
- Interface names in `router.nix`
- Timezone in `configuration.nix`
- VM disk path in `homeassistant.nix`
- Nebula lighthouse IP in `nebula.nix`
- DHCP reservations in `router.nix`

## Security Notes

This configuration is designed for a home lab:
- Passwordless sudo is enabled
- Nebula firewall is fully open (appropriate for trusted overlay networks)
- No secrets management

## More Info

Listen to [Linux Unplugged #650](https://linuxunplugged.com/650) for the full walkthrough.

## License

MIT

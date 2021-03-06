package FusionInventory::Agent::Task::Inventory::Generic::PCI::Controllers;

use strict;
use warnings;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Generic;

sub isEnabled {
    my (%params) = @_;
    return 0 if $params{no_category}->{controller};
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    foreach my $controller (_getControllers(
        logger  => $params{logger},
        dbdir   => $params{dbdir}
    )) {
        $inventory->addEntry(
            section => 'CONTROLLERS',
            entry   => $controller
        );
    }
}

sub _getControllers {
    my @controllers;

    foreach my $device (getPCIDevices(@_)) {

        next unless $device->{PCIID};

        # duplicate entry to avoid modifying it directly
        my $controller = {
            PCICLASS     => $device->{PCICLASS},
            NAME         => $device->{NAME},
            MANUFACTURER => $device->{MANUFACTURER},
            REV          => $device->{REV},
            PCISLOT      => $device->{PCISLOT},
        };
        $controller->{DRIVER} = $device->{DRIVER}
            if $device->{DRIVER};
        $controller->{PCISUBSYSTEMID} = $device->{PCISUBSYSTEMID}
            if $device->{PCISUBSYSTEMID};

        my ($vendor_id, $device_id) = split (/:/, $device->{PCIID});
        $controller->{VENDORID}  = $vendor_id;
        $controller->{PRODUCTID} = $device_id;
        my $subdevice_id = $device->{PCISUBSYSTEMID};

        my $vendor = getPCIDeviceVendor(id => $vendor_id, @_);
        if ($vendor) {
            $controller->{MANUFACTURER} = $vendor->{name};

            if ($vendor->{devices}->{$device_id}) {
                my $entry = $vendor->{devices}->{$device_id};
                $controller->{CAPTION} = $entry->{name};

                $controller->{NAME} =
                    $subdevice_id && $entry->{subdevices}->{$subdevice_id} ?

                    $entry->{subdevices}->{$subdevice_id}->{name} :
                    $entry->{name};
            }
        }

        next unless $device->{PCICLASS};

        $device->{PCICLASS} =~ /^(\S\S)(\S\S)$/x;
        my $class_id = $1;
        my $subclass_id = $2;

        my $class = getPCIDeviceClass(id => $class_id, @_);
        if ($class) {
            $controller->{TYPE} =
                $subclass_id && $class->{subclasses}->{$subclass_id} ?
                    $class->{subclasses}->{$subclass_id}->{name} :
                    $class->{name};
        }

        push @controllers, $controller;
    }

    return @controllers;
}

1;

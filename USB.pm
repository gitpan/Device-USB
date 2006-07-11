package Device::USB;

require 5.006;
use warnings;
use strict;
use Carp;

use Inline (
        C => "DATA",
        LIBS => '-lusb',
	NAME => 'Device::USB',
	VERSION => '0.14',
   );

Inline->init();

#
# Now the Perl code.
#

use Device::USB::Device;
use Device::USB::Bus;

=head1 NAME

Device::USB - Use libusb to access USB devices.

=head1 VERSION

Version 0.14

=cut

our $VERSION='0.14';


=head1 SYNOPSIS

Device::USB provides a Perl wrapper around the libusb library. This
supports Perl code controlling and accessing USB devices.

    use Device::USB;

    my $usb = Device::USB->new();
    my $dev = $usb->find_device( $VENDOR, $PRODUCT );

    printf "Device: %04X:%04X\n", $dev->idVendor(), $dev->idProduct();
    $dev->open();
    print "Manufactured by ", $dev->manufacturer(), "\n",
          " Product: ", $dev->product(), "\n";

    $dev->set_configuration( $CFG );
    $dev->control_msg( @params );
    ...

See the libusb manual for more information about most of the methods. The
functionality is generally the same as the libusb function whose name is
the method name prepended with "usb_".

=head1 DESCRIPTION

This module provides a Perl interface to the C library libusb. This library
supports a relatively full set of functionality to access a USB device. In
addition to the libusb, functioality, Device::USB provides a few
convenience features that are intended to produce a more Perl-ish interface.

These features include:

=over 4

=item *

Using the library initializes it, no need to call the underlying usb_init
function.

=item *

Object interface reduces namespace pollution and provides a better interface
to the library.

=item *

The find_device method finds the device associated with a vendor id and
product id and creates an appropriate Device::USB::Device object to
manipulate the USB device.

=item *

Object interfaces to the bus and device data structures allowing read access
to information about each.

=back

=head1 Device::USB

This class provides an interface to the non-bus and non-device specific
functions of the libusb library. In particular, it provides interfaces to
find busses and devices. It also provides convenience methods that simplify
some of the tasks above.

=head2 FUNCTIONS

=over 4

=cut

#
#  Internal-only, one-time init function.
my $init_ref;
$init_ref = sub
{
    libusb_init();
    $init_ref = sub {};
};

=item new

Create a new Device::USB object for accessing the library.

=cut

sub new
{
    my $class = shift;

    $init_ref->();

    return bless {}, $class;
}

=item debug_mode

This class method enables low-level debugging messages from the library
interface code.

A true argument enables debug mode, a false argument disables it.

=cut

sub debug_mode
{
    my ($class, $enable) = @_;
    
    # force the value to be either 1 or 0
    lib_debug_mode( $enable ? 1 : 0 );
    return;
}


=item find_busses

Returns the number of changes since previous call to the function: the
number of busses added or removed.

=cut

sub find_busses
{
    my $self = shift;
    return libusb_find_busses();
}

=item find_devices

Returns the number of changes since previous call to the function: the
number of devices added or removed. Should be called after find_busses.

=cut

sub find_devices
{
    my $self = shift;
    return libusb_find_devices();
}

=item find_device

Find and a particular USB device based on the vendor and product ids. If more
than one device has the same product id from the same vendor, the fist one
found will be returned.

=over 4

=item vendor

the vendor id

=item product

product id for that vendor

=back

returns a device reference or undef if none was found.

=cut

sub find_device
{
    my $self = shift;
    my ($vendor, $product) = @_;
    return lib_find_usb_device( $vendor, $product );
}

=item list_devices

Find all devices matching a vendor id and optional product id. If no product
id is given, returns all devices found with the supplied vendor id. If a
product id is given, returns all devices matching both the vendor id and
product id.

=over 4

=item vendor

the vendor id

=item product

optional product id for that vendor

=back

returns a list of devices matching the supplied criteria or a reference
to that array in scalar context

=cut

sub list_devices
{
    my $self = shift;
    my ($vendor, $product) = @_;
    my @devices = ();

    foreach my $bus ($self->list_busses())
    {
        foreach my $dev ($bus->devices())
	{
	    if($dev->idVendor() == $vendor &&
	       (!defined $product || $product == $dev->idProduct())
	    )
	    {
	        push @devices, $dev;
	    }
	}
    }

    return wantarray ? @devices : \@devices;
}

=item list_busses

Return the complete list of information after finding busses and devices.

By using this function, you do not need to do the find_* calls yourself.

returns a reference to an array of busses.

=cut

sub list_busses
{
    my $self = shift;
    my $busses = lib_list_busses();

    return wantarray ? @{$busses} : $busses;
}

=item get_busses

Return the complete list of information after finding busses and devices.

Before calling this function, remember to call find_busses and find_devices.

returns a reference to an array of busses.

=cut

sub get_busses
{
    my $self = shift;
    my $busses = lib_get_usb_busses();

    return wantarray ? @{$busses} : $busses;
}

=back

=head1 DIAGNOSTICS

This is an explanation of the diagnostic and error messages this module
can generate.

=head1 DEPENDENCIES

This module depends on the Carp, Inline and Inline::C modules, as well as
the strict and warnings pragmas. Obviously, libusb must be available since
that is the entire reason for the module's existence.

=head1 AUTHOR

G. Wade Johnson (wade at anomaly dot org)
Paul Archer (paul at paularcher dot org)

Houston Perl Mongers Group

Original author: David Davis

=head1 BUGS

Please report any bugs or feature requests to
C<bug-device-usb@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Device::USB>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 LIMITATIONS

So far, this module has only been tested on Linux. It should work on any
OS that supports the libusb library. Several people have reported problems
compiling the module on Windows.

=head1 ACKNOWLEDGEMENTS

Thanks go to various members of the Houston Perl Mongers group for input
on the module. But thanks mostly go to Paul Archer who proposed the project
and helped with the development.

Thanks to Josep Monés Teixidor for fixing the \C<bInterfaceClass> bug.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Houston Perl Mongers

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

__DATA__

__C__

#include <usb.h>

static unsigned bDebug = 0;

void libusb_init()
{
    usb_init();
}

int libusb_find_busses()
{
    return usb_find_busses();
}

int libusb_find_devices()
{
    return usb_find_devices();
}

void *libusb_get_busses()
{
    return usb_get_busses();
}

void *libusb_open(void *dev)
{
    return usb_open( (struct usb_device*)dev );
}

int libusb_close(void *dev)
{
    return usb_close((usb_dev_handle *)dev);
}

int libusb_set_configuration(void *dev, int configuration)
{
    if(bDebug)
    {
        printf( "libusb_set_configuration( %d )\n", configuration );
    }
    return usb_set_configuration((usb_dev_handle *)dev, configuration);
}

int libusb_set_altinterface(void *dev, int alternate)
{
    if(bDebug)
    {
        printf( "libusb_set_altinterface( %d )\n", alternate );
    }
    return usb_set_altinterface((usb_dev_handle *)dev, alternate);
}

int libusb_clear_halt(void *dev, unsigned int ep)
{
    if(bDebug)
    {
        printf( "libusb_clear_halt( %d )\n", ep );
    }
    return usb_clear_halt((usb_dev_handle *)dev, ep);
}

int libusb_reset(void *dev)
{
    return usb_reset((usb_dev_handle *)dev);
}

int libusb_claim_interface(void *dev, int interface)
{
    if(bDebug)
    {
        printf( "libusb_claim_interface( %d )\n", interface );
    }
    return usb_claim_interface((usb_dev_handle *)dev, interface);
}

int libusb_release_interface(void *dev, int interface)
{
    if(bDebug)
    {
        printf( "libusb_release_interface( %d )\n", interface );
    }
    return usb_release_interface((usb_dev_handle *)dev, interface);
}

void libusb_control_msg(void *dev, int requesttype, int request, int value, int index, char *bytes, int size, int timeout)
{
    int i = 0;

    if(bDebug)
    {
        printf( "libusb_control_msg( %#04x, %#04x, %#04x, %#04x, %p, %d, %d )\n",
            requesttype, request, value, index, bytes, size, timeout
        );
	/* maybe need to add support for printing the bytes string. */
    }
    int retval = usb_control_msg((usb_dev_handle *)dev, requesttype, request, value, index, bytes, size, timeout);
    if(bDebug)
    {
        printf( "\t => %d\n",retval );
    }

    Inline_Stack_Vars;

    /* quiet compiler warnings. */
    (void)i;
    (void)ax;
    (void)items;
    /*
     * For some reason, I could not get this string transferred back to the Perl side
     * through a direct copy like in get_simple_string. So, I resorted to returning
     * it on the stack and doing the fixup on the Perl side.
     */
    Inline_Stack_Reset;
    Inline_Stack_Push(sv_2mortal(newSViv(retval)));
    if(retval > 0)
    {
        Inline_Stack_Push(sv_2mortal(newSVpv(bytes, retval)));
    }
    else
    {
        Inline_Stack_Push(sv_2mortal(newSVpv(bytes, 0)));
    }
    Inline_Stack_Done;
}

int libusb_get_string(void *dev, int index, int langid, char *buf, size_t buflen)
{
    if(bDebug)
    {
        printf( "libusb_get_string( %d, %d, %p, %u )\n",
	    index, langid, buf, buflen
	);
    }
    return usb_get_string((usb_dev_handle *)dev, index, langid, buf, buflen);
}

int libusb_get_string_simple(void *dev, int index, char *buf, size_t buflen)
{
    if(bDebug)
    {
        printf( "libusb_get_string_simple( %d, %p, %u )\n",
	    index, buf, buflen
	);
    }
    return usb_get_string_simple((usb_dev_handle *)dev, index, buf, buflen);
}

int libusb_get_descriptor(void *dev, unsigned char type, unsigned char index, void *buf, int size)
{
    return usb_get_descriptor((usb_dev_handle *)dev, type, index, buf, size);
}

int libusb_get_descriptor_by_endpoint(void *dev, int ep, unsigned char type, unsigned char index, void *buf, int size)
{
    return usb_get_descriptor_by_endpoint((usb_dev_handle *)dev, ep, type, index, buf, size);
}

int libusb_bulk_write(void *dev, int ep, char *bytes, int size, int timeout)
{
    return usb_bulk_write((usb_dev_handle *)dev, ep, bytes, size, timeout);
}

int libusb_bulk_read(void *dev, int ep, char *bytes, int size, int timeout)
{
    return usb_bulk_read((usb_dev_handle *)dev, ep, bytes, size, timeout);
}

int libusb_interrupt_write(void *dev, int ep, char *bytes, int size, int timeout)
{
    return usb_interrupt_write((usb_dev_handle *)dev, ep, bytes, size, timeout);
}

int libusb_interrupt_read(void *dev, int ep, char *bytes, int size, int timeout)
{
    return usb_interrupt_read((usb_dev_handle *)dev, ep, bytes, size, timeout);
}

#if 0
int usb_get_driver_np(usb_dev_handle *dev, int interface, char *name, int namelen);
int usb_detach_kernel_driver_np(usb_dev_handle *dev, int interface);
#endif

/* ------------------------------------------------------------
 * Provide Perl-ish interface for accessing busses and devices.
 */

/*
 * Utility function to store BCD encoded number as an appropriate string
 * in a hash under the supplied key.
 */
static void hashStoreBcd( HV *hash, const char *key, long value )
{
    int major = (value >> 8) & 0xff;
    int minor = (value >> 4) & 0xf;
    int subminor = value & 0xf;

    // should not be able to exceed 6.
    char buffer[10] = "";

    sprintf( buffer, "%d.%d%d", major, minor, subminor );

    hv_store( hash, key, strlen( key ), newSVpv( buffer, strlen( buffer ) ), 0 );
}

/*
 * Utility function to store an integer value in a hash under the supplied key.
 */
static void hashStoreInt( HV *hash, const char *key, long value )
{
    hv_store( hash, key, strlen( key ), newSViv( value ), 0 );
}

/*
 * Utility function to store a C-style string in a hash under the supplied key.
 */
static void hashStoreString( HV *hash, const char *key, const char *value )
{
    hv_store( hash, key, strlen( key ), newSVpv( value, strlen( value ) ), 0 );
}

/*
 * Utility function to store an SV in a hash under the supplied key.
 */
static void hashStoreSV( HV *hash, const char *key, SV *value )
{
    hv_store( hash, key, strlen( key ), value, 0 );
}

/*
 * Given a pointer to an array of usb_device, create a hash
 * reference containing the descriptor information.
 */
static SV* build_descriptor(struct usb_device *dev)
{
    HV* hash = newHV();

    hashStoreInt( hash, "bDescriptorType", dev->descriptor.bDescriptorType );
    hashStoreBcd( hash, "bcdUSB", dev->descriptor.bcdUSB );
    hashStoreInt( hash, "bDeviceClass", dev->descriptor.bDeviceClass );
    hashStoreInt( hash, "bDeviceSubClass", dev->descriptor.bDeviceSubClass );
    hashStoreInt( hash, "bDeviceProtocol", dev->descriptor.bDeviceProtocol );
    hashStoreInt( hash, "bMaxPacketSize0", dev->descriptor.bMaxPacketSize0 );
    hashStoreInt( hash, "idVendor", dev->descriptor.idVendor );
    hashStoreInt( hash, "idProduct", dev->descriptor.idProduct );
    hashStoreBcd( hash, "bcdDevice", dev->descriptor.bcdDevice );
    hashStoreInt( hash, "iManufacturer", dev->descriptor.iManufacturer );
    hashStoreInt( hash, "iProduct", dev->descriptor.iProduct );
    hashStoreInt( hash, "iSerialNumber", dev->descriptor.iSerialNumber );
    hashStoreInt( hash, "bNumConfigurations", dev->descriptor.bNumConfigurations );

    return newRV_noinc( (SV*)hash );
}

/*
 * Given a pointer to an array of usb_endpoint_descriptor structs, create a
 * reference to a Perl array containing the same data.
 */
static SV* list_endpoints( struct usb_endpoint_descriptor* endpt, unsigned count )
{
    AV* array = newAV();
    HV* hash = 0;
    unsigned i= 0;

    for(i=0; i < count; ++i)
    {
        av_push( array, newRV_noinc( (SV*)(hash = newHV()) ) );
        hashStoreInt( hash, "bDescriptorType", endpt[i].bDescriptorType );
        hashStoreInt( hash, "bEndpointAddress", endpt[i].bEndpointAddress );
        hashStoreInt( hash, "bmAttributes", endpt[i].bmAttributes );
        hashStoreInt( hash, "wMaxPacketSize ", endpt[i].wMaxPacketSize );
        hashStoreInt( hash, "bInterval", endpt[i].bInterval );
        hashStoreInt( hash, "bRefresh", endpt[i].bRefresh );
        hashStoreInt( hash, "bSynchAddress", endpt[i].bSynchAddress );
    }

    return newRV_noinc( (SV*)array );
}

/*
 * Given a pointer to a usb_interface_descriptor, copy the data into the
 * supplied hash.
 */
static void store_interface( HV* hash, struct usb_interface_descriptor* inter )
{
    hashStoreInt( hash, "bDescriptorType", inter->bDescriptorType );
    hashStoreInt( hash, "bInterfaceNumber", inter->bInterfaceNumber );
    hashStoreInt( hash, "bAlternateSetting", inter->bAlternateSetting );
    hashStoreInt( hash, "bNumEndpoints ", inter->bNumEndpoints );
    hashStoreInt( hash, "bInterfaceClass", inter->bInterfaceClass );
    hashStoreInt( hash, "bInterfaceSubClass", inter->bInterfaceSubClass );
    hashStoreInt( hash, "bInterfaceProtocol", inter->bInterfaceProtocol );
    hashStoreInt( hash, "iInterface", inter->iInterface );
    hashStoreSV( hash, "endpoints",
        list_endpoints( inter->endpoint, inter->bNumEndpoints )
    );
}

/*
 * Given a pointer to an array of usb_interface structs, create a
 * reference to a Perl array containing the same data.
 */
static SV* list_interfaces( struct usb_interface* ints, unsigned count )
{
    AV* array = newAV();
    HV* hash = 0;
    unsigned i= 0;

    for(i=0; i < count; ++i)
    {
        av_push( array, newRV_noinc( (SV*)(hash = newHV()) ) );
        hashStoreInt( hash, "num_altsetting", ints[i].num_altsetting );
	store_interface( hash, ints[i].altsetting );
    }

    return newRV_noinc( (SV*)array );
}


/*
 * Given a pointer to an array of usb_config_descriptor structs, create a
 * reference to a Perl array containing the same data.
 */
static SV* list_configurations(struct usb_config_descriptor *cfg, unsigned count )
{
    AV* array = newAV();
    HV* hash = 0;
    unsigned i= 0;

    for(i=0; i < count; ++i)
    {
        av_push( array, newRV_noinc( (SV*)(hash = newHV()) ) );
        hashStoreInt( hash, "bDescriptorType", cfg[i].bDescriptorType );
        hashStoreInt( hash, "wTotalLength", cfg[i].wTotalLength );
        hashStoreInt( hash, "bNumInterfaces", cfg[i].bNumInterfaces );
        hashStoreInt( hash, "bConfigurationValue", cfg[i].bConfigurationValue );
        hashStoreInt( hash, "iConfiguration", cfg[i].iConfiguration );
        hashStoreInt( hash, "bmAttributes", cfg[i].bmAttributes );
        hashStoreInt( hash, "MaxPower", cfg[i].MaxPower );
	hashStoreSV( hash, "interfaces",
	    list_interfaces( cfg[i].interface, cfg[i].bNumInterfaces )
	);
    }

    return newRV_noinc( (SV*)array );
}

/*
 * Given a pointer to a usb device structure, return a reference to a
 * Perl object containing the same data.
 */
static SV* build_device(struct usb_device *dev)
{
    HV* hash = newHV();

    hashStoreString( hash, "filename", dev->filename );
    hashStoreSV( hash, "descriptor", build_descriptor( dev ) );
    hashStoreSV( hash, "config",
       list_configurations( dev->config, dev->descriptor.bNumConfigurations )
    );
    hashStoreInt( hash, "device", (unsigned long)dev );

    return sv_bless( newRV_noinc( (SV*)hash ),
        gv_stashpv( "Device::USB::Device", 1 )
    );
}

/*
 * Given a pointer to a list of devices, return a reference to a
 * Perl array of device objects.
 */
static SV* list_devices(struct usb_device *dev)
{
    AV* array = newAV();

    for(; 0 != dev; dev = dev->next)
    {
        av_push( array, build_device( dev ) );
    }

    return newRV_noinc( (SV*) array );
}


static SV* build_bus( struct usb_bus *bus )
{
    HV *hash = newHV();

    hashStoreString( hash, "dirname", bus->dirname );
    hashStoreInt( hash, "location", bus->location );
    hashStoreSV( hash, "devices", list_devices( bus->devices ) );

    return sv_bless( newRV_noinc( (SV*)hash ),
        gv_stashpv( "Device::USB::Bus", 1 )
    );
}


/*
 * Return the complete list of information after finding busses and devices.
 *
 * Before calling this function, remember to call find_busses and find_devices.
 *
 * returns a reference to an array of busses.
 */
SV* lib_get_usb_busses()
{
    AV* array = newAV();
    struct usb_bus *bus = 0;

    for(bus = usb_busses; 0 != bus; bus = bus->next)
    {
        av_push( array, build_bus( bus ) );
    }

    return newRV_noinc( (SV*) array );
}

/*
 * Return the complete list of information after finding busses and devices.
 *
 * By using this function, you do not need to do the find_* calls yourself.
 *
 * returns a reference to an array of busses.
 */
SV* lib_list_busses()
{
    usb_find_busses();
    usb_find_devices();

    return lib_get_usb_busses();
}

/*
 * Find a particular device
 *
 *  vendor  - the vendor id
 *  product - product id for that vendor
 *
 * returns a pointer to the device if it is found, NULL otherwise.
 */
SV *lib_find_usb_device( int vendor, int product )
{
    struct usb_bus *bus = 0;

    usb_find_busses();
    usb_find_devices();

    for(bus = usb_busses; 0 != bus; bus = bus->next)
    {
        struct usb_device *dev = 0;
        for(dev = bus->devices; 0 != dev; dev = dev->next)
	{
            if((dev->descriptor.idVendor == vendor) &&
	      (dev->descriptor.idProduct == product))
	    {
                return build_device( dev );
            }
	}
    }

    return &PL_sv_undef;
}

/*
 * Enable or disable debugging mode.
 */
void  lib_debug_mode( int enable )
{
    printf( "Debugging: %s\n", (enable ? "on" : "off") );
    bDebug = enable;
}


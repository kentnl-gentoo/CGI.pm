package CGI::Cookie;

# See the bottom of this file for the POD documentation.  Search for the
# string '=head'.

# You can run this file through either pod2man or pod2html to produce pretty
# documentation in manual or html file format (these utilities are part of the
# Perl 5 distribution).

# Copyright 1995,1996, Lincoln D. Stein.  All rights reserved.
# It may be used and modified freely, but I do request that this copyright
# notice remain attached to the file.  You may modify this module as you 
# wish, but if you redistribute a modified version, please attach a note
# listing the modifications you have made.

# The most recent version and complete docs are available at:
#   http://www.genome.wi.mit.edu/ftp/pub/software/WWW/cgi_docs.html
#   ftp://ftp-genome.wi.mit.edu/pub/software/WWW/

$CGI::Cookie::VERSION='1.02';

use CGI qw/unescape escape/;

# fetch a list of cookies from the environment and
# return as a hash.
sub fetch {
    my $class = shift;
    my $raw_cookie = $ENV{HTTP_COOKIE} || $ENV{COOKIE};
    return () unless $raw_cookie;
    my %results;

    my(@pairs) = split("; ",$raw_cookie);
    foreach (@pairs) {
	my($key,$value) = split("=");
	my(@values) = map unescape($_),split('&',$value);
	$key = unescape($key);
	$results{$key} = $class->new(-name=>$key,-value=>\@values);
    }
    return \%results unless wantarray;
    return %results;
}

sub new {
    my $class = shift;
    my($name,$value,$path,$domain,$secure,$expires) =
	CGI->rearrange([NAME,[VALUE,VALUES],PATH,DOMAIN,SECURE,EXPIRES],@_);

    # Pull out our parameters.
    my @values;
    if (ref($value)) {
	if (ref($value) eq 'ARRAY') {
	    @values = @$value;
	} elsif (ref($value) eq 'HASH') {
	    @values = %$value;
	}
    } else {
	@values = ($value);
    }

    bless my $self = {
	'name'=>$name,
	'value'=>[@values],
	},$class;

    # IE requires the path to be present for some reason.
    ($path = $ENV{'SCRIPT_NAME'})=~s![^/]+$!! unless $path;

    $self->path($path) if defined $path;
    $self->domain($domain) if defined $domain;
    $self->secure($secure) if defined $secure;
    $self->expires($expires) if defined $expires;
    return $self;
}

sub as_string {
    my $self = shift;

    my(@constant_values,$domain,$path,$expires,$secure);

    push(@constant_values,"domain=$domain") if $domain = $self->domain;
    push(@constant_values,"path=$path") if $path = $self->path;
    push(@constant_values,"expires=$expires") if $expires = $self->expires;
    push(@constant_values,'secure') if $secure = $self->secure;

    my($key) = escape($self->name);
    my($cookie) = join("=",$key,join("&",map escape($_),$self->value));
    return join("; ",$cookie,@constant_values);
}

# accessors
sub name {
    my $self = shift;
    my $name = shift;
    $self->{'name'} = $name if defined $name;
    return $self->{'name'};
}

sub value {
    my $self = shift;
    my $value = shift;
    $self->{'value'} = $value if defined $value;
    return wantarray ? @{$self->{'value'}} : $self->{'value'}->[0]
}

sub domain {
    my $self = shift;
    my $domain = shift;
    $self->{'domain'} = $domain if defined $domain;
    return $self->{'domain'};
}

sub secure {
    my $self = shift;
    my $secure = shift;
    $self->{'secure'} = $secure if defined $secure;
    return $self->{'secure'};
}

sub expires {
    my $self = shift;
    my $expires = shift;
    $self->{'expires'} = CGI::expires($expires,'cookie') if defined $expires;
    return $self->{'expires'};
}

sub path {
    my $self = shift;
    my $path = shift;
    $self->{'path'} = $path if defined $path;
    return $self->{'path'};
}

1;

=head1 NAME

CGI::Cookie - Interface to Netscape Cookies

=head1 SYNOPSIS

    use CGI qw/:standard/;
    use CGI::Cookie;

    # Create new cookies and send them
    $cookie1 = new CGI::Cookie(-name=>'ID',-value=>123456);
    $cookie2 = new CGI::Cookie(-name=>'preferences',
                               -value=>{ font => Helvetica,
                                         size => 12 } 
                               );
    print header(-cookie=>[$cookie1,$cookie2]);

    # fetch existing cookies
    %cookies = fetch CGI::Cookie;
    $id = $cookies{'ID'}->value;

=head1 DESCRIPTION

CGI::Cookie is an interface to Netscape (HTTP/1.1) cookies, an
innovation that allows Web servers to store persistent information on
the browser's side of the connection.  Although CGI::Cookie is
intended to be used in conjunction with CGI.pm (and is in fact used by
it internally), you can use this module independently.

For full information on cookies see 

	http://www.ics.uci.edu/pub/ietf/http/rfc2109.txt

=head1 USING CGI::Cookie

CGI::Cookie is object oriented.  Each cookie object has a name and a
value.  The name is any scalar value.  The value is any scalar or
array value (associative arrays are also allowed).  Cookies also have
several optional attributes, including:

=over 4

=item B<1. expiration date>

The expiration date tells the browser how long to hang on to the
cookie.  If the cookie specifies an expiration date in the future, the
browser will store the cookie information in a disk file and return it
to the server every time the user reconnects (until the expiration
date is reached).  If the cookie species an expiration date in the
past, the browser will remove the cookie from the disk file.  If the
expiration date is not specified, the cookie will persist only until
the user quits the browser.

=item B<2. domain>

This is a partial or complete domain name for which the cookie is 
valid.  The browser will return the cookie to any host that matches
the partial domain name.  For example, if you specify a domain name
of ".capricorn.com", then Netscape will return the cookie to
Web servers running on any of the machines "www.capricorn.com", 
"ftp.capricorn.com", "feckless.capricorn.com", etc.  Domain names
must contain at least two periods to prevent attempts to match
on top level domains like ".edu".  If no domain is specified, then
the browser will only return the cookie to servers on the host the
cookie originated from.

=item B<3. path>

If you provide a cookie path attribute, the browser will check it
against your script's URL before returning the cookie.  For example,
if you specify the path "/cgi-bin", then the cookie will be returned
to each of the scripts "/cgi-bin/tally.pl", "/cgi-bin/order.pl",
and "/cgi-bin/customer_service/complain.pl", but not to the script
"/cgi-private/site_admin.pl".  By default, path is set to "/", which
causes the cookie to be sent to any CGI script on your site.

=item B<4. secure flag>

If the "secure" attribute is set, the cookie will only be sent to your
script if the CGI request is occurring on a secure channel, such as SSL.

=back

=head2 Creating New Cookies

	$c = new CGI::Cookie(-name    =>  'foo',
                             -value   =>  'bar',
                             -expires =>  '+3M',
                             -domain  =>  '.capricorn.com',
                             -path    =>  '/cgi-bin/database'
                             -secure  =>  1
	                    );

Create cookies from scratch with the B<new> method.  The B<-name> and
B<-value> parameters are required.  The name must be a scalar value.
The value can be a scalar, an array reference, or a hash reference.
(At some point in the future cookies will support one of the Perl
object serialization protocols for full generality).

B<-expires> accepts any of the relative or absolute date formats
recognized by CGI.pm, for example "+3M" for three months in the
future.  See CGI.pm's documentation for details.

B<-domain> points to a domain name or to a fully qualified host name.
If not specified, the cookie will be returned only to the Web server
that created it.

B<-path> points to a partial URL on the current server.  The cookie
will be returned to all URLs beginning with the specified path.  If
not specified, it defaults to '/', which returns the cookie to all
pages at your site.

B<-secure> if set to a true value instructs the browser to return the
cookie only when a cryptographic protocol is in use.

=head2 Recovering Previous Cookies

	%cookies = fetch CGI::Cookie;

B<fetch> returns an associative array consisting of all cookies
returned by the browser.  The keys of the array are the cookie names.  You
can iterate through the cookies this way:

	%cookies = fetch CGI::Cookie;
	foreach (keys %cookies) {
	   do_something($cookies{$_});
        }

In a scalar context, fetch() returns a hash reference, which may be more
efficient if you are manipulating multiple cookies.
    
=head2 Manipulating Cookies

Cookie objects have a series of accessor methods to get and set cookie
attributes.  Each accessor has a similar syntax.  Called without
arguments, the accessor returns the current value of the attribute.
Called with an argument, the accessor changes the attribute and
returns its new value.

=over 4

=item B<name()>

Get or set the cookie's name.  Example:

	$name = $c->name;
	$new_name = $c->name('fred');

=item B<value()>

Get or set the cookie's value.  Example:

	$value = $c->value;
	@new_value = $c->value(['a','b','c','d']);

B<value()> is context sensitive.  In an array context it will return
the current value of the cookie as an array.  In a scalar context it
will return the B<first> value of a multivalued cookie.

=item B<domain()>

Get or set the cookie's domain.

=item B<path()>

Get or set the cookie's path.

=item B<expires()>

Get or set the cookie's expiration time.

=back

=head1 CAVEATS

This is a new module.  It hasn't been extensively tested.

=head1 AUTHOR INFORMATION

be used and modified freely, but I do request that this copyright
notice remain attached to the file.  You may modify this module as you
wish, but if you redistribute a modified version, please attach a note
listing the modifications you have made.

Address bug reports and comments to:
lstein@genome.wi.mit.edu

=head1 BUGS

This section intentionally left blank.

=head1 SEE ALSO

L<CGI::Carp>, L<CGI>
 
=cut

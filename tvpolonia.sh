#!/bin/sh
# Released under general BSD license, Copyright Eric Windisch.

if [ ! -z $1 ]; then
	cmd="mplayer $1"
else
	cmd=`sed -n -e '/\#\!\/usr\/bin\/perl/,$p;' $0 | /usr/bin/perl`
#mms=`/usr/bin/tvpolonia-perl 2>/dev/null`
fi

if [ ! -z "$cmd" ]; then
	xterm -e $cmd;
fi
echo $cmd;

# exit here or face trying to parse perl via SH ;)
exit 0

# BELOW THIS LINE IS PERL-FILE, we detect location via the hash-bang. #
#!/usr/bin/perl

use Gtk;

our $user="";
our $pass="";
our $speed="300";
our $menu=();
our $last=0;
our @urls=();

init Gtk;
set_locale Gtk;
Gtk->init();

&drawauth;

if (defined ($ARGV[0]))
{
	doMplayer2 ($ARGV[0]);
	exit 0;
}

sub getlist 
{
open (WFD, "/usr/bin/wget \"http://".$user.":".$pass."\@www.tvpolonia.com/highspeed/".$speed."K/__.js\" -O -  2>/dev/null |") or die "Cannot download list.";

while (<WFD>)
{
	my $one, $two;
	if ((($one, $two) = /^menu(.*)\[(.*)\]/) && (! /omowienieR/)) { 
		($menu[$last][section], $menu[$last][$two]) = /.*OnClick=\"(.*)\((.*)\)\".*/;
		push (@ones, $one);
	}
	if (my ($filename) = /Player.fileName.*\"(http:\/\/.*wvx)\";/)
	{
		$filename=~ s/http:\/\//http:\/\/${user}:${pass}\@/;
		$filename=~ s/\"\+sus\+\"/\/WVX\/${speed}K\//;
		
		if (! defined (@{$menu[$last]})) {
			push @urls, $filename;
			$last++;
			next;
		}
		foreach $item (@{$menu[$last]}) {
			$_=$item;
			if (/^[0-9]*$/) { 
				$_=$filename;
				my $b=$_, $c=$_;
				$b=~ s/^(.*)\"\+cup\+\".*$/$1/;
				$c=~ s/.*\"\+cup\+\"(.*)$/$1/;
				push @urls, $b.$item.$c;
			}	
		}
		$last++;
	}
	$one=undef;
	$two=undef;
}
}

sub drawauth
{
	# init widgets
	my $window=new Gtk::Window ("toplevel");
	my $ok_button = new Gtk::Button ("Ok");
	my $cancel_button = new Gtk::Button ("Cancel");
	my $userfield = new Gtk::Entry ();
	my $passfield = new Gtk::Entry ();
	my $label = new Gtk::Label ("Authentication required:");

	# widget settings
	$window->set_title("TvPolonia - authentication");
	$window->set_default_size(200, 50);
#$window->set_policy( FALSE, FALSE, TRUE) ;
	$passfield->set_visibility(0);

	my $vbox = new Gtk::VBox(0, 1);
	my $hbox = new Gtk::HBox(0, 20);

	# callback registration
	$window->signal_connect( "delete_event", \&gtkCloseAppWindow );
	$ok_button->signal_connect( "clicked", \&doAuth, $window, $userfield, $passfield);
	$cancel_button->signal_connect( "clicked", \&gtkCloseAppWindow );

	# do packing here.
	$window->add($vbox);
	$vbox->pack_start($label, 1, 1, 3);

	$label = new Gtk::Label ("Username:");
	$hbox->pack_start($label, 0, 1, 0);
	$hbox->pack_start($userfield, 1, 1, 0);
	$vbox->pack_start($hbox, 0, 1, 0);

	$hbox = new Gtk::HBox(0, 20);
	$label = new Gtk::Label ("Password:");
	$hbox->pack_start($label, 0, 1, 0);
	$hbox->pack_start($passfield, 1, 1, 0);
	$vbox->pack_start($hbox, 0, 1, 0);

	$hbox = new Gtk::HBox(0, 20);
	$hbox->pack_start($ok_button, 1, 1, 0);
	$hbox->pack_start($cancel_button, 1, 1, 0);
	$vbox->pack_start($hbox, 0, 1, 0);

	$window->show_all();
	Gtk->main();
}

sub doAuth 
{
	my ($widget, $window, $userfield, $passfield) = @_;
	$user = $userfield->get_text();
	$pass = $passfield->get_text();
	$window->destroy();

	&getlist;
	&drawlist;
}

sub drawlist 
{
# init widgets
my $window=new Gtk::Window ("toplevel");
my $ok_button = new Gtk::Button ("Watch");
my $save_button = new Gtk::Button ("Save");
my $cancel_button = new Gtk::Button ("Cancel");
my $list = new Gtk::List();
my $sw = new Gtk::ScrolledWindow (undef, undef);

# widget settings
$list->set_selection_mode ('single');
$window->set_title("TvPolonia");
$window->set_default_size(800, 600);

my $vbox = new Gtk::VBox(0, 10);
my $hbox = new Gtk::HBox(0, 10);

# callback registration
$window->signal_connect( "delete_event", \&gtkCloseAppWindow );
$ok_button->signal_connect( "clicked", \&doMplayer, $list, 0 );
$save_button->signal_connect( "clicked", \&doMplayer, $list, 1 );
$cancel_button->signal_connect( "clicked", \&gtkCloseAppWindow );

# do packing here.
$window->add($vbox);
$sw->add_with_viewport($list);
$vbox->pack_start($sw, 1, 1, 0);
$vbox->pack_start($hbox, 0, 1, 0);
$hbox->pack_start($ok_button, 1, 1, 0);
$hbox->pack_start($save_button, 1, 1, 0);
$hbox->pack_start($cancel_button, 1, 1, 0);

foreach my $item (@urls) {
	$list->append_items( new Gtk::ListItem ("$item"));
}

$window->show_all();
Gtk->main();
}

sub gtkCloseAppWindow
{
	Gtk->exit( 0 );
	return 0;
}

sub doMplayer 
{
	my ($button, $list, $save) = @_;
	my @dlist = $list->selection;
	my $item=$dlist[0];
	doMplayer2( $item->children()->get(), $save );
	#gtkCloseappWindow ();	
	Gtk->exit(0);
	return 0;
}

sub doMplayer2
{
	my ($url, $save) = @_;
	my $mms="";

	open (WVX, "wget ".$url." -O - 2>/dev/null |");
	while (<WVX>)
	{
		if (/REF/) {
			s/.*href.*=.*\"(.*)\".*/$1/;
			$mms=$_;	
			if ($save == 1)
			{
				print "mencoder -oac copy -ovc copy ";
			} else {
				print "mplayer ";
			}
			print "$mms";
			#exec ("open -w -s \"mplayer -slave \\\"".$mms."\\\"\"");
		}
	}
}

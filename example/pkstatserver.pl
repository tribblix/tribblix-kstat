#!/usr/bin/env morbo
#
# SPDX-License-Identifier: CDDL-1.0
#

#
# this is a Mojolicious web application, exposing kstats via a REST
# API that a JKstat client can talk to, using the command
#
# jkstat remotebrowser -S http://127.0.0.1:3000/
#
use Tribblix::Kstat;
use Mojolicious::Lite -signatures;
use JSON;

#
# The JKstat REST API uses 3 routes:
# /getkcid - retrieve the kstat chain id, as a bare number
# /list - retrieve an array with the list of kstats
# /get/module/instance/name - retrieve the module:instance:name: kstat
#

#
# get a kstat handle we'll use for everything else
#
my $ks = Tribblix::Kstat->new(strip_strings => 1);

#
# FIXME run a $ks->update() each request
#
get '/getkcid' => {
    text => $ks->getKCID()
};

#
get '/list' => sub ($c) {
    my $first = 1;
    my $l = "[\n";
    $ks->update();
    foreach my $m (keys(%$ks)) {
	my $mh = $ks->{$m};
	foreach my $i (keys(%$mh)) {
	    my $ih = $mh->{$i};
	    foreach my $n (keys(%$ih)) {
		my $nh = $ih->{$n};
		if ($first) {
		    $first = 0;
		} else {
		    $l = $l . ",\n";
		}
		$l = $l
		    . "{\"class\":\"" . $nh->{class} . "\","
		    . "\"type\":" . $nh->{"ks_type"} . ","
		    . "\"module\":\"" . $m . "\","
		    . "\"instance\":" . $i . ","
		    . "\"name\":\"" . $n . "\"}\n";
	    }
	}
    }
    $l = $l . "]\n";
    $c->render(text => $l);
};

#
# the hash we get back from perl includes class, crtime, snaptime, and ks_type
# as data members, so strip those out and put them into the metadata
#
# we mostly encode into json by hand, because we know exactly what format
# the JKstat client expects. However, data values use encode_json() which
# will detect whether the value is a string and automatically stringify.
#
get '/get/:module/:instance/:name' => sub ($c) {
    my $module = $c->stash('module');
    my $instance = $c->stash('instance');
    my $name = $c->stash('name');
    my $first = 1;
    my $l = "";
    $ks->update();
    foreach my $m (keys(%$ks)) {
	next if ($m ne $module);
	my $mh = $ks->{$m};
	foreach my $i (keys(%$mh)) {
	    next if ($i ne $instance);
	    my $ih = $mh->{$i};
	    foreach my $n (keys(%$ih)) {
		next if ($n ne $name);
		my $nh = $ih->{$n};
		my @stats = keys(%$nh);
		$l = $l
		    . "{\"class\":\"" . $nh->{class} . "\","
		    . "\"type\":" . $nh->{"ks_type"} . ","
		    . "\"module\":\"" . $m . "\","
		    . "\"instance\":" . $i . ","
		    . "\"name\":\"" . $n . "\","
		    . "\"crtime\":" . $nh->{"crtime"} . ","
		    . "\"snaptime\":" . $nh->{"snaptime"} . ","
		    . "\"data\":" . "{";
		foreach my $s (grep {$_ ne "class" && $_ ne "ks_type" && $_ ne "crtime" && $_ ne "snaptime"} @stats) {
		    if ($first) {
			$first = 0;
		    } else {
			$l = $l . ",";
		    }
		    $l = $l
			. "\"" . $s . "\":" . encode_json($nh->{$s})
		}
		$l = $l
		    . "}";
		$l = $l
		    . "}\n";
	    }
	}
    }
    $c->render(text => $l);
};

app->start;

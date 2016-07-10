use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'venetian',
    AUTHOR           => q{Christian Kühnel <christian.kuehnel@gmail.com>},
    VERSION		     => '0.1.0',
    #ABSTRACT_FROM    => 'lib/Venetian.pm',
    LICENSE          => 'Apache_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::MockModule' => 0,
        'Time::HiRes' => 0,
        'Test::Perl::Critic' => 0,
        'experimental' => 0,
        'Test::Pod' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'fhem-venetian-*' },
);

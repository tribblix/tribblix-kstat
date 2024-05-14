use 5.008003;
use ExtUtils::MakeMaker;

WriteMakefile(
    VERSION_FROM => "Kstat.pm",
    NAME         => "Tribblix::Kstat",
    CONFIGURE_REQUIRES => { ExtUtils::MakeMaker => 6.52 },
    INC          => "-I/usr/platform/sun4u/include",
    LIBS         => [ '-lkstat' ],
    EXE_FILES    => [ 'bin/perlkstat' ],
);

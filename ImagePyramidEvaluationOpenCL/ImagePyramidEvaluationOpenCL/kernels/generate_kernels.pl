#!perl -w
use strict;
use Path::Tiny;
use POSIX;
use Cwd qw(realpath);
use File::Basename;

my $cwd = dirname(realpath($0));
require $cwd . '/derivative_kernels.pl';
our %kernels;

my $generateSeparationFilter = 1;
my $generatedWarning = "/* This file is generated. Do not modify. */\n\n";

generate_defines("filter_images_defines.base.cl");
generate_filter("filter_images_normal.base.cl");
generate_filter("filter_images_local.base.cl");
generate_filter_optimum("filter_images.base.cl");
generate_derivativeKernels("filter_images_normal.base.cl", "filter_images_predefined-normal.cl");  # Use only normal
generate_derivativeKernels("filter_images_local.base.cl", "filter_images_predefined-local.cl");    # Use only local
#generate_derivativeKernels("filter_images_normal.base.cl", "filter_images_local.base.cl", "filter_images_optimum-predefined.cl");   # Use local memory for filter sizes > 3 x 3

sub generate_defines
{
    my $filenameBase = $_[0];
    my $base = path($filenameBase)->slurp({binmode => ":encoding(UTF-8)"}) or die "Can't read file " . $filenameBase . ": $!\n";
    my $code = $generatedWarning;

    $code .= "// Normal filter\n";
    
    foreach my $N (3, 5, 7, 9) {
        my $baseCopy = $base;
        my $N_HALF = floor($N / 2);
        my $LOCAL_SIZE = 16 + 2 * $N_HALF;
        
        $baseCopy =~ s{NxN}{${N}x$N}gm;
        $baseCopy =~ s{// GENERATE_N$}{$N}gm;
        $baseCopy =~ s{// GENERATE_N-HALF$}{$N_HALF}gm;
        $baseCopy =~ s{// GENERATE_LOCAL_SIZE_COLS$}{$LOCAL_SIZE // 16 + 2 * $N_HALF}gm;
        $baseCopy =~ s{// GENERATE_LOCAL_SIZE_ROWS$}{$LOCAL_SIZE // 16 + 2 * $N_HALF}gm;
        
        $code .= $baseCopy;
        if ($N != 9) {
            $code .= "\n";
        }
    }
    
    $code .= "\n// Max possible filter size with local memory (arbitrary chosen)\n";
    $code .= "#define LOCAL_SIZE_COLS_21x21 36 // 16 + 2 * 10\n";
    $code .= "#define LOCAL_SIZE_ROWS_21x21 36 // 16 + 2 * 10\n";
    
    if ($generateSeparationFilter) {
        $code .= "\n";
        $code .= "// Separation filter\n";
        
        # 1xN filters
        foreach my $N (3, 5, 7, 9) {
            my $baseCopy = $base;
            my $N_HALF = floor($N / 2);
            my $LOCAL_SIZE_COLS = 16 + 2 * $N_HALF;
            my $LOCAL_SIZE_ROWS = 16;
            
            $baseCopy =~ s{COLS_NxN // GENERATE_N}{COLS_1x$N $N}gm;
            $baseCopy =~ s{COLS_HALF_NxN // GENERATE_N-HALF}{COLS_HALF_1x$N $N_HALF}gm;
            $baseCopy =~ s{ROWS_NxN // GENERATE_N}{ROWS_1x$N 1}gm;
            $baseCopy =~ s{ROWS_HALF_NxN // GENERATE_N-HALF}{ROWS_HALF_1x$N 0}gm;
            $baseCopy =~ s{LOCAL_SIZE_COLS_NxN // GENERATE_LOCAL_SIZE_COLS}{LOCAL_SIZE_COLS_1x$N $LOCAL_SIZE_COLS // 16 + 2 * $N_HALF}gm;
            $baseCopy =~ s{LOCAL_SIZE_ROWS_NxN // GENERATE_LOCAL_SIZE_ROWS}{LOCAL_SIZE_ROWS_1x$N $LOCAL_SIZE_ROWS // 16}gm;
            
            $code .= $baseCopy;
            if ($N != 9) {
                $code .= "\n";
            }
        }
        
        $code .= "\n";
        
        # Nx1 filters
        foreach my $N (3, 5, 7, 9) {
            my $baseCopy = $base;
            my $N_HALF = floor($N / 2);
            my $LOCAL_SIZE_COLS = 16;
            my $LOCAL_SIZE_ROWS = 16 + 2 * $N_HALF;
            
            $baseCopy =~ s{COLS_NxN // GENERATE_N}{COLS_${N}x1 1}gm;
            $baseCopy =~ s{COLS_HALF_NxN // GENERATE_N-HALF}{COLS_HALF_${N}x1 0}gm;
            $baseCopy =~ s{ROWS_NxN // GENERATE_N}{ROWS_${N}x1 $N}gm;
            $baseCopy =~ s{ROWS_HALF_NxN // GENERATE_N-HALF}{ROWS_HALF_${N}x1 $N_HALF}gm;
            $baseCopy =~ s{LOCAL_SIZE_COLS_NxN // GENERATE_LOCAL_SIZE_COLS}{LOCAL_SIZE_COLS_${N}x1 $LOCAL_SIZE_COLS // 16}gm;
            $baseCopy =~ s{LOCAL_SIZE_ROWS_NxN // GENERATE_LOCAL_SIZE_ROWS}{LOCAL_SIZE_ROWS_${N}x1 $LOCAL_SIZE_ROWS // 16 + 2 * $N_HALF}gm;
            
            $code .= $baseCopy;
            if ($N != 9) {
                $code .= "\n";
            }
        }
    }
    
    my $codeFilename = $filenameBase =~ s/\.base//r;
    path($codeFilename)->spew({binmode => ":encoding(UTF-8)"}, $code) or die "Can't write file " . $codeFilename . ": $!\n";
}

sub substDefaults {
        my $multiplicity = $_[0];
        my $baseCopy = $_[1];
        
        $baseCopy =~ s{MULTIPLICITY}{$multiplicity}gm;
        $baseCopy =~ s{/\*\s*GENERATE_TYPE\s*\*/}{type_$multiplicity}gm;
        $baseCopy =~ s{^\s*// GENERATE_KERNEL_(BEGIN|END)\s*$}{}gm;
        $baseCopy =~ s{\s*/\* GENERATE_REMOVE_PREDEFINED:(.+?)\*/}{$1}gs;
        $baseCopy =~ s{_DERIV}{}gm;

        if ($multiplicity eq "single") {
            $baseCopy =~ s{\s*/\* GENERATE_DOUBLE:(?:.+?)\*/}{}gs;
        }
        else {
            $baseCopy =~ s{/\* GENERATE_DOUBLE:(.+?)\*/}{$1}gs;
        }
        
        return $baseCopy;
    }

sub generate_filter
{
    my $filenameBase = $_[0];
    my $base = path($filenameBase)->slurp({binmode => ":encoding(UTF-8)"}) or die "Can't read file " . $filenameBase . ": $!\n";
    my $code = $generatedWarning;
    
    foreach my $multiplicity ("single", "double") {
        my $baseCopy = $base;
        
        $baseCopy =~ s{_NxN}{}gm;
        $baseCopy =~ s{\bROWS\b}{filterRows}gm;
        $baseCopy =~ s{\bROWS_HALF\b}{filterRowsHalf}gm;
        $baseCopy =~ s{\bCOLS\b}{filterCols}gm;
        $baseCopy =~ s{\bCOLS_HALF\b}{filterColsHalf}gm;
        $baseCopy =~ s{LOCAL_SIZE_(COLS|ROWS)}{LOCAL_SIZE_$1_21x21}gm;
        $baseCopy =~ s{,\s+// GENERATE_REMOVE$}{,}gm;
        $baseCopy =~ s{\s*// GENERATE_REMOVE$}{}gm;
        $baseCopy =~ s{/\* GENERATE_REMOVE:([^*]+)\*/}{$1}gm;
        
        $baseCopy = substDefaults($multiplicity, $baseCopy);
        
        $code .= $baseCopy . "\n";
        $code .= "// Normal filter\n";

        foreach my $N (3, 5, 7, 9) {
            my $baseCopy = $base;
            my $N_HALF = floor($N / 2);
            my $LOCAL_SIZE = 16 + 2 * $N_HALF;

            $baseCopy =~ s{NxN}{${N}x$N}gm;
            $baseCopy =~ s{^.*\s+// GENERATE_REMOVE\n}{}gm;
            $baseCopy =~ s{/\* GENERATE_REMOVE:([^*]+)\*/}{}gm;
            
            $baseCopy = substDefaults($multiplicity, $baseCopy);
        
            $code .= $baseCopy;
            if ($N != 9) {
                $code .= "\n";
            }
        }
        
        if ($generateSeparationFilter) {
            $code .= "\n";
            $code .= "// Separation filter\n";
            
            foreach my $N (3, 5, 7, 9) {
                my $baseCopy = $base;
                my $N_HALF = floor($N / 2);
                my $LOCAL_SIZE = 16 + 2 * $N_HALF;
                
                $baseCopy =~ s{NxN}{1x$N}gm;
                $baseCopy =~ s{^.*,\s+// GENERATE_REMOVE\n}{}gm;
                $baseCopy =~ s{/\* GENERATE_REMOVE:([^*]+)\*/}{}gm;
                
                $baseCopy = substDefaults($multiplicity, $baseCopy);
                
                $code .= $baseCopy;
                if ($N != 9) {
                    $code .= "\n";
                }
            }
            
            $code .= "\n";
            
            foreach my $N (3, 5, 7, 9) {
                my $baseCopy = $base;
                my $N_HALF = floor($N / 2);
                my $LOCAL_SIZE = 16 + 2 * $N_HALF;

                $baseCopy =~ s{NxN}{${N}x1}gm;
                $baseCopy =~ s{^.*,\s+// GENERATE_REMOVE\n}{}gm;
                $baseCopy =~ s{/\* GENERATE_REMOVE:([^*]+)\*/}{}gm;
                
                $baseCopy = substDefaults($multiplicity, $baseCopy);
                
                $code .= $baseCopy;
                if ($N != 9) {
                    $code .= "\n";
                }
            }
        }
    }
    
    my $codeFilename = $filenameBase =~ s/\.base//r;
    path($codeFilename)->spew({binmode => ":encoding(UTF-8)"}, $code) or die "Can't write file " . $codeFilename . ": $!\n";
}

sub generate_filter_optimum
{
    my $filenameBase = $_[0];
    my $filenameNormal = $filenameBase =~ s/images/images_normal/r;
    my $filenameLocal = $filenameBase =~ s/images/images_local/r;
    my $baseNormal = path($filenameNormal)->slurp({binmode => ":encoding(UTF-8)"}) or die "Can't read file $filenameNormal: $!\n";
    my $baseLocal = path($filenameLocal)->slurp({binmode => ":encoding(UTF-8)"}) or die "Can't read file $filenameLocal: $!\n";
    my $code = $generatedWarning;
    
    foreach my $multiplicity ("single", "double") {
        # Local default
        my $baseCopy = $baseLocal;
        
        $baseCopy =~ s{_NxN}{}gm;
        $baseCopy =~ s{\bROWS\b}{filterRows}gm;
        $baseCopy =~ s{\bROWS_HALF\b}{filterRowsHalf}gm;
        $baseCopy =~ s{\bCOLS\b}{filterCols}gm;
        $baseCopy =~ s{\bCOLS_HALF\b}{filterColsHalf}gm;
        $baseCopy =~ s{LOCAL_SIZE_(COLS|ROWS)}{LOCAL_SIZE_$1_21x21}gm;
        $baseCopy =~ s{,\s+// GENERATE_REMOVE$}{,}gm;
        $baseCopy =~ s{/\* GENERATE_REMOVE:([^*]+)\*/}{$1}gm;
        
        $baseCopy = substDefaults($multiplicity, $baseCopy);
        
        $code .= "// For filters with max size of 21x21\n";
        $code .= $baseCopy . "\n";
        
        # Normal default
        $baseCopy = $baseNormal;
        
        $baseCopy =~ s{_NxN}{}gm;
        $baseCopy =~ s{\bROWS\b}{filterRows}gm;
        $baseCopy =~ s{\bROWS_HALF\b}{filterRowsHalf}gm;
        $baseCopy =~ s{\bCOLS\b}{filterCols}gm;
        $baseCopy =~ s{\bCOLS_HALF\b}{filterColsHalf}gm;
        $baseCopy =~ s{,\s+// GENERATE_REMOVE$}{,}gm;
        $baseCopy =~ s{/\* GENERATE_REMOVE:([^*]+)\*/}{$1}gm;
        
        $baseCopy = substDefaults($multiplicity, $baseCopy);
        
        $code .= "// For filters of any size > 21x21\n";
        $code .= $baseCopy . "\n";

        foreach my $N (3, 5, 7, 9) {
            my $baseCopy;
            if ($N <= 3) {
                $baseCopy = $baseNormal;
            }
            else {
                $baseCopy = $baseLocal;
            }
            
            my $N_HALF = floor($N / 2);
            my $LOCAL_SIZE = 16 + 2 * $N_HALF;

            $baseCopy =~ s{NxN}{${N}x$N}gm;
            $baseCopy =~ s{^.*,\s+// GENERATE_REMOVE\n}{}gm;
            $baseCopy =~ s{/\* GENERATE_REMOVE:([^*]+)\*/}{}gm;
            
            $baseCopy = substDefaults($multiplicity, $baseCopy);
        
            $code .= $baseCopy;
            if ($N != 9) {
                $code .= "\n";
            }
        }
    }
    
    my $codeFilename = $filenameBase =~ s/\.base/_optimum/r;
    path($codeFilename)->spew({binmode => ":encoding(UTF-8)"}, $code) or die "Can't write file " . $codeFilename . ": $!\n";
}

sub generate_derivativeKernels
{
    my $filenameNormal;
    my $filenameLocal;
    my $filenameOutput;
    
    my $optimise;
    if (scalar @_ == 2) { # Use either only local or only normal
        $filenameNormal = $_[0];
        $filenameLocal = $_[0];
        $filenameOutput = $_[1];
        $optimise = 0;
    }
    elsif (scalar @_ == 3) {
        $filenameNormal = $_[0];
        $filenameLocal = $_[1];
        $filenameOutput = $_[2];
        $optimise = 1;  # Generate optimised filter (normal for 3x3, local for the rest) when both the base for local and normal is given
    }
    
    my $useLocal = $filenameLocal =~ m/local/ ? 1 : 0;
    
    my $baseNormal = path($filenameNormal)->slurp({binmode => ":encoding(UTF-8)"}) or die "Can't read file " . $filenameNormal . ": $!\n";
    my $baseLocal = path($filenameLocal)->slurp({binmode => ":encoding(UTF-8)"}) or die "Can't read file " . $filenameLocal . ": $!\n";
    my $code = $generatedWarning;
    
    foreach my $multiplicity ("single", "double") {
        my @keys = sort { $a cmp $b} keys %kernels;
        
        # In case of double filtering remove all Gy keys since they are added manually
        if ($multiplicity eq "double") {
            @keys = grep ! /Gy/, @keys;
        }
        
        foreach my $key (@keys) {   # Gx_3x3, Gx_5x5, ...
            $key =~ m/([^_]+)_(\d)x(\d)/;
            my $deriv = $1;
            my $rows = $2;
            my $cols = $3;
            my $rowsHalf = int($rows / 2);
            my $colsHalf = int($cols / 2);

            my $baseCopy;
            if ($optimise) {
                $baseCopy = $rows <= 3 ? $baseNormal : $baseLocal;
            }
            else {
                $baseCopy = $useLocal ? $baseLocal : $baseNormal;
            }
            
            # First key is Gx and second key is Gy in double filtering
            my $key2;
            if ($multiplicity eq "double") {
                $deriv = "GxGy";
                $key2 = "Gy_${rows}x$cols";
            }
            
            my $kernelCode = "\n";
            
            # Execute the convolution
            for (my $y = -$rowsHalf; $y <= $rowsHalf; ++$y) {
                my $codeYCoord = "\tcoordCurrent.y = coordBase.y";
                if ($y != 0) {
                    $codeYCoord .= " + $y";
                }
                $codeYCoord .= ";\n";
                
                my $codeYCoordPrinted = 0;
                
                for (my $x = -$colsHalf; $x <= $colsHalf; ++$x) {
                    # Retrieve the value for the kernel
                    my $value = $kernels{$key}[($y + $rowsHalf) * $cols + $x + $colsHalf];
                    my $value2;
                    if ($multiplicity eq "double") {
                        $value2 = $kernels{$key2}[($y + $rowsHalf) * $cols + $x + $colsHalf];
                    }
                    
                    # Check if the filter kernel values are non-zero
                    my $validValue = 0;
                    my $sum = "";
                    my $sum2 = "";
                    if ($multiplicity eq "double") {
                        if ($value != 0) {
                            $validValue = 1;
                            
                            # Use as max digits after the period as available
                            my $valuePrecision = ($value =~ /\.(.*)/) ? length($1) : 1;
                            
                            # It is important that the numbers are float literals (i.e. they have .f appended); otherwise additional overhead is introduced due to type casting
                            $sum = sprintf("\tsum.x += color * %.*ff;\n", $valuePrecision, $value);
                        }
                        if ($value2 != 0) {
                            $validValue = 1;
                            my $value2Precision = ($value2 =~ /\.(.*)/) ? length($1) : 1;
                            $sum2 = sprintf("\tsum.y += color * %.*ff;\n", $value2Precision, $value2);
                        }
                    }
                    else {
                        if ($value != 0) {
                            $validValue = 1;
                            my $valuePrecision = ($value =~ /\.(.*)/) ? length($1) : 1;
                            $sum = sprintf("\tsum += color * %.*ff;\n", $valuePrecision, $value);
                        }
                    }
                    
                    if ($validValue) {
                        # The y coordinates must only be printed once per row
                        if ($codeYCoordPrinted == 0) {
                            $kernelCode .= $codeYCoord;
                            $codeYCoordPrinted = 1;
                        }

                        $kernelCode .= "\tcoordCurrent.x = coordBase.x";
                        if ($x != 0) {
                            $kernelCode .= " + $x";
                        }
                        $kernelCode .= ";\n";
                        
                        my $localCode;
                        if ($optimise) {
                            $localCode = $rows > 3 ? 1 : 0;
                        }
                        else {
                            $localCode = $useLocal ? 1 : 0;
                        }
                        
                        if ($localCode) {
                            $kernelCode .= "\tcolor = localBuffer[coordCurrent.y * LOCAL_SIZE_COLS_${rows}x$cols + coordCurrent.x];\n";
                        }
                        else {
                            $kernelCode .= "\tcoordBorder = borderCoordinate(coordCurrent, rows, cols, border);\n";
                            $kernelCode .= "\tcolor = read_imagef(imgIn, sampler, coordBorder).x;\n";
                        }
                        
                        if ($sum ne "") {
                            $kernelCode .= $sum;
                        }
                        if ($sum2 ne "") {
                            $kernelCode .= $sum2;
                        }
                    }
                }
            }
            
            $kernelCode =~ s/\n\n$/\n/;
            
            # The rest are just the normal substitutions
            $baseCopy =~ s{NxN}{${rows}x$cols}gm;
            $baseCopy =~ s{DERIV}{$deriv}gm;
            $baseCopy =~ s{^\s*// GENERATE_KERNEL_BEGIN.*GENERATE_KERNEL_END\s*$}{$kernelCode}gsm;
            $baseCopy =~ s{^.*\s+// GENERATE_REMOVE\n}{}gm;
            $baseCopy =~ s{/\* GENERATE_REMOVE:([^*]+)\*/}{}gm;
            $baseCopy =~ s{\s*/\* GENERATE_REMOVE_PREDEFINED:(?:.+?)\*/(?:\*/)?}{}gs;
            $baseCopy = substDefaults($multiplicity, $baseCopy);    # Must be called at the end since it would otherwise remove some of code markings needed previously
            
            $code .= $baseCopy . "\n";
        }
    }
    
    $code =~ s/\n\n$/\n/;
    
    path($filenameOutput)->spew({binmode => ":encoding(UTF-8)"}, $code) or die "Can't write file " . $filenameOutput . ": $!\n";
}

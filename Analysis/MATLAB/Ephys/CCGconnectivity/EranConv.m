% EranCONV                  predictor and p-values for CCG using convolution
%
% CALL                      [ PVALS, PRED, QVALS ] = EranCONV( CCH, W )
%
% GETS                      CCH         vector (a single CCG) or matrix (CCGs in columns)
%                                           has to be non-negative integers (counts)
%                           W           window width [samples] {5}
%                                           has to be non-negative integer no larger than the CCH length
% RETURNS                   PVALS       p-values (bin-wise)
%                           QVALS       p-values (bin-wise) for inhibition
%                           PRED        predictor(expected values)
%
% ADVICE                    for minimal run-time, collect multiple CCHs in
%                               the columns of CCH and call this routine once
%
% ADVANCED CALL              [ PVALS, PRED ] = EranCONV( CCH, W, WINTYPE, HF )
%
% ADVANCED ARGUMENTS        WINTYPE     window type;
%                                           {'gauss'} - with SD of W/2; has optimal statistical properties
%                                           'rect' - of W samples; equivalent to jittering one spike train by a rectangular window of width W
%                                           'triang' - of ~2W samples; equivalent to jittering both trains by a rectangular window of width W
%                           HF          hollowed fraction; default value depends on window type;
%                                           gauss: 0.6
%                                           rectangular: 0.42
%                                           triangular: 0.63
%
% REFERENCE                 Stark and Abeles JNM 2009

% 12-aug-09 Eran Stark

function [ pvals, pred ,qvals] = EranConv( CCH, W, WINTYPE, HF )

% 1. CHECK ARGUMENTS
nargs = nargin;
if nargs < 1, error( 'missing argument CCH' ), end
[ m, n ] = size( CCH );
if m * n <= 1, error( 'improper argument CCH' ), end
if m == 1
    CCH = CCH'; 
    nsamps = n;
    ncchs = 1;
else
    nsamps = m;
    ncchs = n;
end
nlags = ( nsamps - 1 ) / 2;
if ( sum( sum( CCH - round( CCH ) ) ) ) || ( sum( sum( CCH < 0 ) ) > 0 )
    error( 'improper argument CCH (must contain non-negative integers)' )
end
    
if nargs < 2 || isempty( W ), W = 5; end
if W ~= round( W ) || W < 1
    error( 'W must be non-negative interger' )
end

if nargs < 3 || isempty( WINTYPE ), WINTYPE = 'gauss'; end
WINTYPE = lower( WINTYPE );

if nargs < 4 || isempty( HF ),
    switch WINTYPE
        case 'gauss', HF = 0.6;
        case 'rect', HF = 0.42;
        case 'triang', HF = 0.63;
    end
else
    if HF < 0 || HF > 1
        error( 'HF not in range (0-1)' )
    end
end

% 2. PREPARE THE CONVOLUTION WINDOW
switch WINTYPE
    case 'gauss'
        SDG = W / 2;
        if round( SDG ) == SDG % even W
            win = local_gausskernel( SDG, 6 * SDG + 1 );
            cidx = SDG * 3 + 1;
        else
            win = local_gausskernel( SDG, 6 * SDG + 2 ); 
            cidx = SDG * 3 + 1.5;
        end
    case 'rect'
        if W / 2 == floor( W / 2 ) % even
            win = ones( 1, W + 1 );
            cidx = W / 2 + 1;
        else
            win = ones( 1, W );
            cidx = ceil( W / 2 );
        end
    case 'triang'
        if W / 2 == floor( W / 2 ) % even
            win = triang( 2 * W + 1 );
            cidx = W + 1;
        else
            win = triang( 2 * W - 1 );
            cidx = W;
        end
    otherwise
        error( 'un-supported window type' )
end
win( cidx ) = win( cidx ) * ( 1 - HF );
win = win / sum( win );      
if nsamps < ( 1.5 * length( win ) )
    error( 'CCH-W mismatch (CCHs should be in columns; otherwise reduce W or elongate CCH)' )
end

% 3. COMPUTE A PREDICTOR BY CONVOLVING THE CCH WITH THE WINDOW:
pred = local_firfilt( CCH, win );

% 4. COMPUTE P-VALUE BASED ON A POISSON DISTRIBUTION WITH A CONTINUITY CORRECTION:
% pvals = 1 - poisscdf( CCH - 1, pred ) - poisspdf( CCH, pred ) .* rand( nsamps, ncchs );
pvals = 1 - poisscdf( CCH - 1, pred ) - poisspdf( CCH, pred ) *0.5;

% now do it for inhibitory case

% qvals = poisscdf( CCH - 1, pred ) + poisspdf( CCH, pred ) .* rand( nsamps, ncchs );
qvals = poisscdf( CCH - 1, pred ) + poisspdf( CCH, pred ) .* 0.5;

% qvals = 1 - poisscdf( pred, CCH-1 ) - poisspdf( pred, CCH ) .* rand( nsamps, ncchs );

return

% LOCAL FUNCTIONS
function Y = local_firfilt( x, W ) % zero-phase lag low-pass filtering of x's columns with the FIR W
C = length( W );
D = ceil( C / 2 ) - 1;
Y = filter( W, 1, [ flipud( x( 1 : C, : ) ); x; flipud( x( end - C + 1 : end, : ) ) ] );
Y = Y( 1 + C + D : end - C + D, : );
return

function K = local_gausskernel( sigmaX, N ) % 1D Gaussian kernel K with N samples and SD sigmaX
x = -( N - 1 ) / 2 : ( N - 1 ) / 2;
K = 1 / ( 2 * pi * sigmaX ) * exp( -( x.^2 / 2 / sigmaX^2 ) );
return

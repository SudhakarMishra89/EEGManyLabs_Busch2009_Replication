function [PixelsPerDegree, DegreesPerPixel]=VisAng2(res,sz,vdist)
% function [pixperdeg, degperpix]=VisAng2(res,sz,vdist)
%
% Takes as input
%     res - the resolution of the monitor
%     sz - the size of the monitor in cm
% (these values can either be along a single dimension or
% for both the width and height)
%     vdist - the viewing distance in cm.
%
% Calculates the visual angle subtended by a single pixel
%
% Returns the pixels per degree
% and it's reciprocal - the degrees per pixel (in degrees, not radians)
%
% written by IF 7/2000
% modified by Niko 19. November 2008

% params.res = [screenWidth, screenHeight];
% params.sz = [ 36, 27 ];
% params.vdist = 46;

pix = sz./res; %calculates the size of a pixel in cm
DegreesPerPixel = (2*atan(pix./(2*vdist))).*(180/pi);
PixelsPerDegree = 1./DegreesPerPixel;
PixelsPerMinute = PixelsPerDegree / 60;

% % 7 degrees eccentricity
% ecc = 7 * pixperdeg;
% 
% % a stimulus of 7 arc minutes
% stimsize = 7 * pixperminute;
% 
% disp( [' Degrees per pixel: ', num2str(degperpix(1))] );
% disp( [' Pixels per degree: ', num2str(pixperdeg(1))] );
% disp( [' Pixels per minute: ', num2str(pixperminute(1))] );
% disp( [' Pixels for eccentricity of 7 deg.: ', num2str(ecc(1))] );
% disp( [' Pixels for stimulus size of 7 min.: ', num2str(stimsize(1))] );

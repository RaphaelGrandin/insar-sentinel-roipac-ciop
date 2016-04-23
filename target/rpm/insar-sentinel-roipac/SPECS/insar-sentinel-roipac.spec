%define __jar_repack 0
Name: insar-sentinel-roipac
Version: 1.0
Release: ciop
Summary: Two pass Sentinel-1 interferometric processing dcs application using ROI_PAC
License: ${project.inceptionYear}, Terradue, GPL
Distribution: Terradue ${project.inceptionYear}
Group: air
Packager: Terradue
Provides: insar-sentinel-roipac
Requires: roi_pac
Requires: snaphu
Requires: tcsh
Requires: python
autoprov: yes
autoreq: yes
Prefix: /application
BuildArch: noarch
BuildRoot: /home/raphaelgrandin/insar-sentinel-roipac-ciop/target/rpm/insar-sentinel-roipac/buildroot

%description
Sentinel-1 interferometry using ROI_PAC

%install
if [ -d $RPM_BUILD_ROOT ];
then
  mv /home/raphaelgrandin/insar-sentinel-roipac-ciop/target/rpm/insar-sentinel-roipac/tmp-buildroot/* $RPM_BUILD_ROOT
else
  mv /home/raphaelgrandin/insar-sentinel-roipac-ciop/target/rpm/insar-sentinel-roipac/tmp-buildroot $RPM_BUILD_ROOT
fi

%files
%defattr(664,root,ciop,775)
 "/application"
%attr(775,root,ciop)  "/application/sentinel-roipac/run.sh"
%attr(775,root,ciop)  "/application/template_b/run.sh"
%attr(775,root,ciop)  "/application/template_a/run.sh"
%attr(775,root,ciop)  "/application/node_prepare/run.sh"

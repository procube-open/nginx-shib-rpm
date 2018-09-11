FROM centos:7
MAINTAINER "Mitsuru Nakakawaji" <mitsuru@procube.jp>
RUN groupadd -g 111 builder
RUN useradd -g builder -u 111 builder
ENV HOME /home/builder
WORKDIR ${HOME}
ENV NGINX_VERSION "1.15.3-1"
RUN yum -y update \
    && yum -y install unzip wget sudo lsof openssh-clients telnet bind-utils tar tcpdump vim initscripts \
        gcc openssl-devel zlib-devel pcre-devel lua lua-devel rpmdevtools make deltarpm \
        perl-devel perl-ExtUtils-Embed GeoIP-devel libxslt-devel gd-devel which redhat-lsb-core
RUN mkdir -p /tmp/buffer
COPY core.patch shibboleth.patch nginx.spec.patch nginx.conf.patch /tmp/buffer/
USER builder
RUN mkdir -p ${HOME}/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
RUN echo "%_topdir %(echo ${HOME})/rpmbuild" > ${HOME}/.rpmmacros
RUN cp /tmp/buffer/* ${HOME}/rpmbuild/SOURCES/
RUN wget --no-verbose -O rpmbuild/SOURCES/ngx_devel_kit-0.3.0.tar.gz https://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz
RUN wget --no-verbose -O rpmbuild/SOURCES/lua-nginx-module-0.10.13.tar.gz https://github.com/openresty/lua-nginx-module/archive/v0.10.13.tar.gz
RUN wget --no-verbose -O rpmbuild/SOURCES/nginx-goodies-nginx-sticky-module-ng-08a395c66e42.tar.gz https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng/get/08a395c66e42.tar.gz
RUN wget --no-verbose -O rpmbuild/SOURCES/nginx-http-shibboleth-2.0.1.tar.gz https://github.com/nginx-shib/nginx-http-shibboleth/archive/v2.0.1.tar.gz
RUN wget --no-verbose -O rpmbuild/SOURCES/headers-more-nginx-module-0.33.tar.gz https://github.com/openresty/headers-more-nginx-module/archive/v0.33.tar.gz
# ADD https://github.com/yaoweibin/nginx_ajp_module/archive/v0.3.0.tar.gz rpmbuild/SOURCES/nginx_ajp_module-0.3.0.tar.gz
# this cause
# /root/rpmbuild/BUILD/nginx-1.10.1/nginx_ajp_module-0.3.0/ngx_http_ajp_module.c: In function 'ngx_http_ajp_store':
# /root/rpmbuild/BUILD/nginx-1.10.1/nginx_ajp_module-0.3.0/ngx_http_ajp_module.c:467:30: error: comparison between pointer and integer [-Werror]
#      if (alcf->upstream.cache != NGX_CONF_UNSET_PTR
# Last Commits for master branch on Feb 28, 2015
COPY nginx_ajp_module-master.tar.gz rpmbuild/SOURCES/nginx_ajp_module-master.tar.gz
RUN mkdir ${HOME}/srpms \
    && cd srpms \
    && wget https://nginx.org/packages/mainline/centos/7/SRPMS/nginx-${NGINX_VERSION}.el7_4.ngx.src.rpm \
    && rpm -ivh ${HOME}/srpms/nginx-${NGINX_VERSION}.el7_4.ngx.src.rpm
RUN cd rpmbuild/SPECS \
    && patch -p 1 nginx.spec < ../SOURCES/nginx.spec.patch
RUN cd rpmbuild/SOURCES \
    && patch < nginx.conf.patch
CMD ["/usr/bin/rpmbuild","-bb","rpmbuild/SPECS/nginx.spec"]

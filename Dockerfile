FROM sdal/ldap-ssh-c7
MAINTAINER "Aaron D. Schroeder" <aschroed@vt.edu>

# Install R Package Prerequisites
RUN yum install -y openssl-devel unzip wget p7zip && \
    yum groupinstall -y 'Development Tools'

# Get Microsoft R Open
RUN cd /tmp/ && \
    wget https://mran.microsoft.com/install/mro/3.4.0/microsoft-r-open-3.4.0.tar.gz && tar -xvzf microsoft-r-open-3.4.0.tar.gz

RUN /tmp/microsoft-r-open/install.sh -a -u

# Configure CRAN Repositories
# RUN echo "r <- getOption('repos'); r['CRAN'] <- 'https://cloud.r-project.org/'; options(repos = r);" >> ~/.Rprofile

COPY 01-setup_Rprofile_site.R 01-setup_Rprofile_site.R
RUN Rscript 01-setup_Rprofile_site.R

# Install R Package Prerequisites
RUN yum install -y postgresql-devel && \
    yum install -y libcurl libcurl-devel xml2 libxml2-devel && \
    yum install -y libjpeg-turbo-devel librsvg2-devel && \
    yum install -y udunits2 udunits2-devel && \
    yum install -y geos-devel v8-314-devel && \
    yum install -y gsl-devel && \
    yum install -y openssl098e passwd pandoc && \
    yum install -y locales which && \
    yum install -y dejavu-sans-fonts dejavu-serif-font && \
    yum install -y ImageMagick ImageMagick-devel && \
    yum install -y libgfortran && \
    yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel

# no need for these since we compile them from source below
# RUN yum install -y gdal gdal-devel proj proj-devel proj-epsg && \

COPY 02-01-wget_files.txt 02-02-wget_sha256sum.txt 03-01-7z_sha256sum.txt pre_compiled_bin /tmp/

RUN cd /tmp/ && \
    sha256sum -c 02-02-wget_sha256sum.txt && \
    sleep 10 && \
    7za e gdal.7z.001 && \
    sha256sum -c 03-01-7z_sha256sum.txt && \
    sleep 10 && \
    tar -zxvf gdal-2.2.0-bin.tar.gz && \
    tar -zxvf proj-4.9.3-bin.tar.gz && \
    sleep 10

RUN cd /tmp/ && \
    cd gdal-2.2.0 && \
    make install

RUN cd /tmp/ && \
    cd proj-4.9.3 && \
    make install

# fix rgdal
RUN echo "/usr/local/lib" >> /etc/ld.so.conf.d/R-dependencies-x86_64.conf && \
    ldconfig

# Fix C++11 error
COPY Makeconf /usr/lib64/microsoft-r/3.4/lib64/R/etc/Makeconf

RUN which java && \
    java -version && \
    R CMD javareconf

COPY 04-check_rpkgs.R 04-check_rpkgs.R
RUN Rscript 04-check_rpkgs.R

CMD ["/usr/sbin/init"]

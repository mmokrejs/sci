# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header:  $

inherit autotools distutils eutils flag-o-matic toolchain-funcs versionator python multilib

DESCRIPTION="SALOME : The Open Source Integration Platform for Numerical Simulation. GUI component"
HOMEPAGE="http://www.salome-platform.org"
SRC_URI="http://files.opencascade.com/Salome${PV}/src${PV}.tar.gz"

LICENSE="GPL-2"
KEYWORDS="~amd64 ~x86"
SLOT="0"
IUSE="debug doc mpi opengl vtkviewer"

RDEPEND="opengl?  ( virtual/opengl )
	 mpi?     ( sys-cluster/mpich2 )
	 debug?   ( dev-util/cppunit )"

DEPEND="${RDEPEND}
	 >=sci-misc/salome-kernel-${PV}"

MODULE_NAME="GUI"
MY_S="${WORKDIR}/src${PV}/${MODULE_NAME}_SRC_${PV}"
INSTALL_DIR="/opt/salome-${PV}/${MODULE_NAME}"
GUI_ROOT_DIR="/opt/salome-${PV}/${MODULE_NAME}"
export OPENPBS="/usr"


src_unpack() {
	python_version
	distutils_python_version

	if ! built_with_use sci-libs/vtk python ; then
		die "You must rebuild sci-libs/vtk with python USE flag"
	fi

	unpack ${A}
	cd "${WORKDIR}/src${PV}"
	epatch "${FILESDIR}"/${P}.patch
	epatch "${FILESDIR}"/${P}_sip-4.1.7.patch
	epatch "${FILESDIR}"/${P}_qwt-4.patch
	epatch "${FILESDIR}"/${P}_configure_in_base.patch

	# Python 2.5 support
	if version_is_at_least "2.5" "${PYVER}"; then
		epatch "${FILESDIR}"/${P}_pyobject.patch
	fi

	# Gcc 4.3 support
	if version_is_at_least "4.3" $(gcc-version) ; then
		epatch "${FILESDIR}"/${P}-gcc-4.3.patch
	fi

	# If vtk-5.O is used, include directory is named vtk-5.0 and not vtk
	if has_version ">=sci-libs/vtk-5.0" && has_version "<sci-libs/vtk-5.2" ; then
	   append-flags -I/usr/include/vtk-5.0
	   epatch "${FILESDIR}"/${P}-vtk-5.0.patch
	fi
	# If vtk-5.2 is used, include directory is named vtk-5.2 and not vtk
	if has_version ">=sci-libs/vtk-5.2" ; then
	   append-flags -I/usr/include/vtk-5.2
	   epatch "${FILESDIR}"/${P}-vtk-5.2.patch
	fi

	cd "${MY_S}"

	rm -r -f autom4te.cache
	./build_configure
}


src_compile() {
	local myconf=""
	cd "${MY_S}"

	# CXXFLAGS are slightly modified to allow the compilation of
	# salome-gui with OpenCascade and gcc-4.1.x
	if version_is_at_least "4.1" $(gcc-version) ; then
		append-flags -ffriend-injection -fpermissive
	fi

	# Compiler and linker flags
	if use amd64 ; then
		append-flags -m64
	fi

	# Quick hack to fix the patch to vtkLibs
	append-flags -L/usr/$(get_libdir)/python${PYVER}/site-packages/vtk

	# Fix a bug concerning a missing header	
	append-flags -I${MY_S}/../KERNEL_SRC_${PV}/src/Basics/Test

	# Specifying --without-<flag> for mpich
	# has the same effect as turning it on
	# so we just ommit it if it's not required to turn it off
	if use mpi ; then
		myconf="${myconf} --with-mpich"
	fi

	# Configuration
	econf --prefix=${INSTALL_DIR} \
	      --datadir=${INSTALL_DIR}/share/salome \
	      --docdir=${INSTALL_DIR}/doc/salome \
	      --infodir=${INSTALL_DIR}/share/info \
	      --libdir=${INSTALL_DIR}/$(get_libdir)/salome \
	      --with-python-site=${INSTALL_DIR}/$(get_libdir)/python${PYVER}/site-packages/salome \
	      --with-python-site-exec=${INSTALL_DIR}/$(get_libdir)/python${PYVER}/site-packages/salome \
	      --enable-corba-gen \
	      --enable-pyConsole \
	      --enable-glViewer \
	      --enable-plot2dViewer \
	      --enable-supervGraphViewer \
	      --enable-occViewer \
	      --enable-salomeObject \
	      ${myconf} \
	      $(use_enable debug ) \
	      $(use_enable !debug production ) \
	      $(use_with debug cppunit /usr ) \
	      $(use_with opengl opengl /usr) \
	      $(use_enable vtkviewer vtkViewer) \
	|| die "configuration failed"

	# Compilation
	MAKEOPTS="-j1" emake || die "Compilation failed"
}


src_install() {
	cd "${MY_S}"

	# Installation
	emake prefix="${D}/${INSTALL_DIR}" \
	      docdir="${D}/${INSTALL_DIR}/doc/salome" \
	      infodir="${D}/${INSTALL_DIR}/share/info" \
	      datadir="${D}/${INSTALL_DIR}/share/salome" \
	      libdir="${D}/${INSTALL_DIR}/$(get_libdir)/salome" \
	      pythondir="${D}/${INSTALL_DIR}/$(get_libdir)/python${PYVER}/site-packages" install \
	|| die "emake install failed"

	if use amd64 ; then
		dosym ${INSTALL_DIR}/lib64 ${INSTALL_DIR}/lib
	fi

	echo "${MODULE_NAME}_ROOT_DIR=${INSTALL_DIR}" > ./90${P}
	echo "LDPATH=${INSTALL_DIR}/$(get_libdir)/salome" >> ./90${P}
	echo "PATH=${INSTALL_DIR}/bin/salome" >> ./90${P}
	echo "PYTHONPATH=${INSTALL_DIR}/$(get_libdir)/python${PYVER}/site-packages/salome" >> ./90${P}
	doenvd 90${P}
	rm adm_local/Makefile adm_local/unix/make_commence adm_local/unix/make_conclude adm_local/unix/make_omniorb
	insinto "${INSTALL_DIR}"
	doins -r adm_local
	if use doc ; then
		dodoc AUTHORS INSTALL NEWS README README.FIRST.txt
	fi

}

pkg_postinst() {
	elog "Run \`env-update && source /etc/profile\`"
	elog "now to set up the correct paths."
	elog ""
}

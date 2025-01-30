# Distributed under the terms of the GNU General Public License v2

EAPI=7

DISTUTILS_EXT=1
DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3+ pypy3 )
PYTHON_REQ_USE='tk?,threads(+)'

inherit distutils-r1 flag-o-matic virtualx toolchain-funcs prefix

DESCRIPTION="Pure python plotting library with matlab like syntax"
HOMEPAGE="https://matplotlib.org/"
SRC_URI="https://files.pythonhosted.org/packages/23/6d/2917ed23b17a8c4d1d59974a574cae0a365c392ba8820c8824b03a02f376/matplotlib-3.6.3.tar.gz -> matplotlib-${PV}.tar.gz"

# Main license: matplotlib
# Some modules: BSD
# matplotlib/backends/qt4_editor: MIT
# Fonts: BitstreamVera, OFL-1.1
LICENSE="BitstreamVera BSD matplotlib MIT OFL-1.1"
SLOT="0"
KEYWORDS="*"
IUSE="cairo doc excel examples gtk3 latex qt5 tk wxwidgets"

# internal copy of pycxx highly patched
#	dev-python/pycxx
RDEPEND="
	>=dev-python/cycler-0.10.0[${PYTHON_USEDEP}]
	>=dev-python/kiwisolver-1.2.0[${PYTHON_USEDEP}]
	>=dev-python/numpy-1.18.2[${PYTHON_USEDEP}]
	>=dev-python/pyparsing-1.5.6[${PYTHON_USEDEP}]
	dev-python/python-dateutil:0[${PYTHON_USEDEP}]
	>=dev-python/pytz-2019.3[${PYTHON_USEDEP}]
	>=dev-python/six-1.14.0[${PYTHON_USEDEP}]
	dev-python/versioneer[${PYTHON_USEDEP}]
	media-fonts/dejavu
	media-fonts/stix-fonts
	media-libs/freetype:2
	media-libs/libpng:0
	>=media-libs/qhull-2013
	>=www-servers/tornado-6.0.4[${PYTHON_USEDEP}]
	cairo? (
		dev-python/cairocffi[${PYTHON_USEDEP}]
	)
	excel? (
		dev-python/xlwt[${PYTHON_USEDEP}]
	)
	gtk3? (
		dev-python/pygobject:3[cairo?,${PYTHON_USEDEP}]
		x11-libs/gtk+:3[introspection]
	)
	latex? (
		virtual/latex-base
		app-text/dvipng
		app-text/ghostscript-gpl
		app-text/poppler[utils]
		dev-texlive/texlive-fontsrecommended
		dev-texlive/texlive-latexextra
		dev-texlive/texlive-xetex
	)
	qt5? (
		dev-python/PyQt5[gui,widgets,${PYTHON_USEDEP}]
	)
	wxwidgets? (
		dev-python/wxpython[${PYTHON_USEDEP}]
	)
"

BDEPEND="
	${RDEPEND}
	dev-python/setuptools[${PYTHON_USEDEP}]
	dev-python/setuptools_scm_git_archive[${PYTHON_USEDEP}]
	virtual/pkgconfig
	doc? (
		>=app-text/dvipng-1.15-r1
		>=dev-python/colorspacious-1.1.2[${PYTHON_USEDEP}]
		>=dev-python/pillow-7.1.1[${PYTHON_USEDEP}]
		>=dev-python/ipython-1.18.2[${PYTHON_USEDEP}]
		>=dev-python/numpydoc-0.9.2[${PYTHON_USEDEP}]
		>=sci-libs/scipy-1.4.1[${PYTHON_USEDEP}]
		>=dev-python/sphinx-1.3.1[${PYTHON_USEDEP}]
		>=dev-python/sphinx-gallery-0.3.1-r1[${PYTHON_USEDEP}]
		>=dev-python/xlwt-1.3.0-r1[${PYTHON_USEDEP}]
		dev-texlive/texlive-latexextra
		dev-texlive/texlive-fontsrecommended
		dev-texlive/texlive-latexrecommended
		>=media-gfx/graphviz-2.42.3[cairo]
	)
"

pkg_setup() {
	unset DISPLAY # bug #278524
}

use_setup() {
	local uword="${2:-${1}}"
	if use "${1}"; then
		echo "${uword} = True"
		echo "${uword}agg = True"
	else
		echo "${uword} = False"
		echo "${uword}agg = False"
	fi
}

python_prepare_all() {
	sed \
		-e 's/matplotlib.pyparsing_py[23]/pyparsing/g' \
		-i lib/matplotlib/{mathtext,fontconfig_pattern}.py \
		|| die "sed pyparsing failed"

	sed -e 's|setuptools_scm>=4,<7|setuptools_scm>=4|g' -i setup.py || \
		die "sed setup.py setuptools_scm failed"

	hprefixify setupext.py

	rm -rf libqhull || die

	export XDG_RUNTIME_DIR="${T}/runtime-dir"
	mkdir "${XDG_RUNTIME_DIR}" || die
	chmod 0700 "${XDG_RUNTIME_DIR}" || die

	distutils-r1_python_prepare_all
}

python_configure_all() {
	append-flags -fno-strict-aliasing
	append-cppflags -DNDEBUG  # or get old trying to do triangulation
	tc-export PKG_CONFIG
}

python_configure() {
	mkdir -p "${BUILD_DIR}" || die

	# create setup.cfg (see setup.cfg.template for any changes).

	# common switches.
	cat > "${BUILD_DIR}"/setup.cfg <<- EOF || die
		[directories]
		basedirlist = ${EPREFIX}/usr
		[provide_packages]
		pytz = False
		dateutil = False
		[libs]
		system_freetype = True
		system_qhull = True
		[packages]
		tests = False
		[gui_support]
		agg = True
		pyside = False
		pysideagg = False
		qt4 = False
		qt4agg = False
		$(use_setup cairo)
		$(use_setup gtk3)
		$(use_setup qt5)
		$(use_setup tk)
	EOF

	if use gtk3 && use cairo; then
		echo "gtk3cairo = True" >> "${BUILD_DIR}"/setup.cfg || die
	else
		echo "gtk3cairo = False" >> "${BUILD_DIR}"/setup.cfg || die
	fi

	if python_is_python3; then
		cat >> "${BUILD_DIR}"/setup.cfg <<- EOF || die
			gtk = False
			gtkagg = False
			wx = False
			wxagg = False
		EOF
	else
		cat >> "${BUILD_DIR}"/setup.cfg <<-EOF || die
			$(use_setup gtk2 gtk)
			$(use_setup wxwidgets wx)
		EOF
	fi
}

wrap_setup() {
	local MAKEOPTS=-j1
	local -x MPLSETUPCFG="${BUILD_DIR}"/setup.cfg
	unset DISPLAY
	"$@"
}

python_compile() {
	wrap_setup distutils-r1_python_compile --build-lib="${BUILD_DIR}"/lib
}

python_compile_all() {
	if use doc; then
		cd doc || die

		# necessary for in-source build
		local -x PYTHONPATH="${BUILD_DIR}"/build/lib:${PYTHONPATH}

		VARTEXFONTS="${T}"/fonts \
		emake SPHINXOPTS= O=-Dplot_formats=png:100 html
	fi
}

python_install() {
	wrap_setup distutils-r1_python_install

	# mpl_toolkits namespace
	python_moduleinto mpl_toolkits
	python_domodule lib/mpl_toolkits/__init__.py
}

python_install_all() {
	use doc && local HTML_DOCS=( doc/build/html/. )

	distutils-r1_python_install_all

	if use examples; then
		dodoc -r examples
		docompress -x /usr/share/doc/${PF}/examples
	fi

	find "${D}" -name '*.pth' -delete || die
}

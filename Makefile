PORTNAME=	libtensorflow1
DISTVERSIONPREFIX=	v
DISTVERSION=	1.15.5
DISTVERSIONSUFFIX=
PORTREVISION=	2
CATEGORIES=	science

MAINTAINER=	freebsd-ports@otoh.org
COMMENT=	C API for TensorFlow, an open source platform for machine learning

LICENSE=	APACHE20 THIRD_PARTY_TF_C_LICENSES
LICENSE_COMB=	multi
LICENSE_NAME_THIRD_PARTY_TF_C_LICENSES=	Third-Party TensorFlow C Licenses
LICENSE_FILE_APACHE20=	${WRKSRC}/LICENSE
LICENSE_FILE_THIRD_PARTY_TF_C_LICENSES=	${WRKDIR}/THIRD_PARTY_TF_C_LICENSES
LICENSE_PERMS_THIRD_PARTY_TF_C_LICENSES=	dist-mirror dist-sell \
						pkg-mirror pkg-sell auto-accept

ONLY_FOR_ARCHS=	amd64

BUILD_DEPENDS=	bash:shells/bash \
		bazel029<1:devel/bazel029 \
		git:devel/git

FLAVORS=	default noavx
FLAVOR?=	${FLAVORS:[1]}
noavx_PKGNAMESUFFIX=	-noavx
noavx_CONFLICTS_INSTALL=	libtensorflow1
default_CONFLICTS_INSTALL=	libtensorflow1-noavx
CONFLICTS_INSTALL=	science/libtensorflow2

USES=		gmake python:3.7-3.9,build

USE_GITHUB=	yes
GH_ACCOUNT=	tensorflow
GH_PROJECT=	tensorflow
.include "Makefile.gh_tuple"

USE_LDCONFIG=	yes

CC?=		clang

BINARY_ALIAS=	python3=${PYTHON_CMD} python=${PYTHON_CMD}

SOVERSION=	${DISTVERSION}
PLIST_SUB=	SOVERSION=${SOVERSION}

OPTIONS_DEFINE=	CUDA OPENCL_SYCL ROCM XLA
OPTIONS_DEFAULT=	AVX

OPTIONS_SINGLE=			CPUFEATURE
OPTIONS_SINGLE_CPUFEATURE=	AVX AVX2 NOAVX
.if ${FLAVOR:U} == noavx
OPTIONS_EXCLUDE:=	${OPTIONS_SINGLE_CPUFEATURE}
.endif

CPUFEATURE_DESC=  Vector Processing Extensions

NOAVX_DESC=	Disable Advanced Vector Extensions
AVX_DESC=	Enable Advanced Vector Extensions (AVX)
AVX2_DESC=	Enable Advanced Vector Extensions v2 (AVX2)

NOAVX_VARS=	BAZEL_ARGS=
AVX_VARS=	BAZEL_ARGS="--copt=-march=core-avx-i --host_copt=-march=core-avx-i"
AVX2_VARS=	BAZEL_ARGS="--copt=-march=core-avx2 --host_copt=-march=core-avx2"

CUDA_DESC=	Enable Compute Unified Device Architecture (CUDA) for Nvidia GPUs
CUDA_VARS=	TF_ENABLE_CUDA=1
CUDA_VARS_OFF=	TF_ENABLE_CUDA=0

OPENCL_SYCL_DESC=	Enable OpenCL Sycl
OPENCL_SYCL_VARS=	TF_NEED_OPENCL_SYCL=1
OPENCL_SYCL_VARS_OFF=	TF_NEED_OPENCL_SYCL=0

ROCM_DESC=	Enable Radeon Open Computer (ROCm) for AMD GPUs
ROCM_VARS=	TF_ENABLE_ROCM=1
ROCM_VARS_OFF=	TF_ENABLE_ROCM=0

XLA_DESC=	Enable Accelerated Linear Algebra (XLA)
XLA_VARS=	TF_ENABLE_XLA=1
XLA_VARS_OFF=	TF_ENABLE_XLA=0

BAZEL_ARGS+=  --action_env=PATH=${PATH} \
    --color=no \
    --discard_analysis_cache \
    --distdir=${DISTDIR} \
    --local_cpu_resources=${MAKE_JOBS_NUMBER} \
    --nokeep_state_after_build \
    --noshow_loading_progress \
    --noshow_progress \
    --notrack_incremental_state \
    --subcommands \
    --verbose_failures \
    --worker_max_instances=${MAKE_JOBS_NUMBER}

BAZEL_OPTS=	--output_user_root=${WRKDIR}/bazel_out

.include <bsd.port.options.mk>
.if ${OPSYS} == FreeBSD && ${OSVERSION} > 1200000 && ${OSVERSION} < 1300000
EXTRA_PATCHES=	${PATCHDIR}/extra-patch-third_party_repo.bzl
.endif

post-extract:
# THIRD_PARTY_TF_C_LICENSES is generated as a Bazel build target (see
# //tensorflow/tools/lib_package:clicenses) and the empty file written
# here will be overwritten. Creation of this file is to satisfy checks.
	@${TOUCH} ${WRKDIR}/THIRD_PARTY_TF_C_LICENSES

post-patch:
	${REINPLACE_CMD} -e 's,%%PYTHON_CMD%%,${PYTHON_CMD},' \
			-e 's,%%LOCALBASE%%,${LOCALBASE},' \
		${WRKSRC}/.bazelrc

do-configure:
	@cd ${WRKSRC} && ${SETENV} \
	  CC_OPT_FLAGS="-I${LOCALBASE}/include" \
	  PREFIX="${LOCALBASE}" \
	  PYTHON_BIN_PATH=${PYTHON_CMD} \
	  PYTHON_LIB_PATH="${PYTHON_SITELIBDIR}" \
	  TF_CONFIGURE_IOS=0 \
	  TF_DOWNLOAD_CLANG=0 \
	  TF_NEED_OPENCL_SYCL=${TF_NEED_OPENCL_SYCL} \
	  TF_ENABLE_XLA=${TF_ENABLE_XLA} \
	  TF_IGNORE_MAX_BAZEL_VERSION=0 \
	  TF_NEED_CUDA=${TF_ENABLE_CUDA} \
	  TF_NEED_MPI=0 \
	  TF_NEED_ROCM=${TF_ENABLE_ROCM} \
	  TF_NEED_TENSORRT=0 \
	  TF_SET_ANDROID_WORKSPACE=0 \
	  ${LOCALBASE}/bin/bash ./configure

do-build:
	@cd ${WRKSRC} && ${LOCALBASE}/bin/bazel ${BAZEL_OPTS} build \
	  ${BAZEL_ARGS} \
	  //tensorflow/tools/lib_package:clicenses_generate \
	  //tensorflow/tools/lib_package:libtensorflow.tar.gz

do-test:
	@cd ${WRKSRC} && ${LOCALBASE}/bin/bazel ${BAZEL_OPTS} test \
	  ${BAZEL_ARGS} \
	  --test_env=CC=${CC} \
	  //tensorflow/tools/lib_package:libtensorflow_test

pre-install:
	${CP} ${WRKSRC}/bazel-bin/tensorflow/tools/lib_package/THIRD_PARTY_TF_C_LICENSES \
	  ${WRKDIR}/THIRD_PARTY_TF_C_LICENSES
	${MKDIR} ${WRKDIR}/lib_package
	(cd ${WRKDIR}/lib_package && ${TAR} xvf \
	  ${WRKSRC}/bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz)
	${MKDIR} ${STAGEDIR}${PREFIX}/include/tensorflow/c/eager

do-install:
.for f in c_api_experimental.h c_api.h eager/c_api.h \
	tf_attrtype.h tf_datatype.h tf_status.h tf_tensor.h
	${INSTALL_DATA} ${WRKDIR}/lib_package/include/tensorflow/c/${f} \
	  ${STAGEDIR}${PREFIX}/include/tensorflow/c/${f}
.endfor
.for l in libtensorflow libtensorflow_framework
	${INSTALL_PROGRAM} ${WRKDIR}/lib_package/lib/${l}.so.${SOVERSION} \
	  ${STAGEDIR}${PREFIX}/lib/
	${RLN} ${STAGEDIR}${PREFIX}/lib/${l}.so.${SOVERSION} \
	  ${STAGEDIR}${PREFIX}/lib/${l}.so.1
	${RLN} ${STAGEDIR}${PREFIX}/lib/${l}.so.1 \
	  ${STAGEDIR}${PREFIX}/lib/${l}.so
.endfor

.include <bsd.port.mk>

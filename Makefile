PORTNAME=  libtensorflow1
DISTVERSIONPREFIX=  v
DISTVERSION=  1.15.5
DISTVERSIONSUFFIX=
CATEGORIES=  science

MAINTAINER=  freebsd-ports@otoh.org
COMMENT=  C API for TensorFlow, an open source platform for machine learning

LICENSE=  APACHE20 THIRD_PARTY_TF_C_LICENSES
LICENSE_COMB=  multi
LICENSE_NAME_THIRD_PARTY_TF_C_LICENSES=  Third-Party TensorFlow C Licenses
LICENSE_FILE_APACHE20=  ${WRKSRC}/LICENSE
LICENSE_FILE_THIRD_PARTY_TF_C_LICENSES=  ${WRKDIR}/THIRD_PARTY_TF_C_LICENSES
LICENSE_PERMS_THIRD_PARTY_TF_C_LICENSES=  dist-mirror dist-sell pkg-mirror pkg-sell auto-accept

CONFLICTS_INSTALL= science/libtensorflow2

ONLY_FOR_ARCHS=  amd64

BUILD_DEPENDS=  bash:shells/bash \
		bazel:devel/bazel029 \
	  git:devel/git

USES=  gmake python:3.7-3.9,build
BINARY_ALIAS=  python3=${PYTHON_CMD}
BINARY_ALIAS+=  python=${PYTHON_CMD}

USE_GITHUB=  yes
GH_ACCOUNT=  tensorflow
GH_PROJECT=  tensorflow

USE_LDCONFIG=  yes

OPTIONS_DEFINE=  CUDA ROCM XLA

OPTIONS_SINGLE= CPUFEATURE
OPTIONS_SINGLE_CPUFEATURE= NOAVX AVX AVX2

NOAVX_DESC= Disable Advanced Vector Extensions
AVX_DESC=  Enable Advanced Vector Extensions (AVX)
AVX2_DESC=  Enable Advanced Vector Extensions v2 (AVX2)

NOAVX_VARS= BAZEL_ARGS=""
AVX_VARS=   BAZEL_ARGS="--copt=-march=core-avx-i --host_copt=-march=core-avx-i"
AVX2_VARS=  BAZEL_ARGS="--copt=-march=core-avx2 --host_copt=-march=core-avx2"

CUDA_DESC=  Enable Compute Unified Device Architecture (CUDA) for Nvidia GPUs
CUDA_VARS=  TF_ENABLE_CUDA=1
CUDA_VARS_OFF=  TF_ENABLE_CUDA=0

ROCM_DESC=  Enable Radeon Open Computer (ROCm) for AMD GPUs
ROCM_VARS=  TF_ENABLE_ROCM=1
ROCM_VARS_OFF=  TF_ENABLE_ROCM=0

XLA_DESC=  Enable Accelerated Linear Algebra (XLA)
XLA_VARS=  TF_ENABLE_XLA=1
XLA_VARS_OFF=  TF_ENABLE_XLA=0

OPTIONS_DEFAULT= AVX

BAZEL_OPTS=  --output_user_root=${WRKDIR}/bazel_out
CC?=  clang

post-extract:
	# THIRD_PARTY_TF_C_LICENSES is generated as a Bazel build target (see
	# //tensorflow/tools/lib_package:clicenses) and the empty file written
	# here will be overwritten. Creation of this file is to satisfy checks.
	@${TOUCH} ${WRKDIR}/THIRD_PARTY_TF_C_LICENSES

do-configure:
	@cd ${WRKSRC} && ${SETENV} \
	  CC_OPT_FLAGS="-I${LOCALBASE}/include" \
	  PREFIX="${LOCALBASE}" \
	  PYTHON_BIN_PATH=${PYTHON_CMD} \
	  PYTHON_LIB_PATH="${PYTHON_SITELIBDIR}" \
	  TF_CONFIGURE_IOS=0 \
	  TF_DOWNLOAD_CLANG=0 \
	  TF_ENABLE_XLA=${TF_ENABLE_XLA} \
	  TF_IGNORE_MAX_BAZEL_VERSION=0 \
	  TF_NEED_CUDA=${TF_ENABLE_CUDA} \
	  TF_NEED_ROCM=${TF_ENABLE_ROCM} \
	  TF_NEED_TENSORRT=0 \
	  TF_SET_ANDROID_WORKSPACE=0 \
	  ${LOCALBASE}/bin/bash ./configure

do-build:
	@cd ${WRKSRC} && ${LOCALBASE}/bin/bazel ${BAZEL_OPTS} build \
	  ${BAZEL_ARGS} \
	  --action_env=PATH=${PATH} \
	  --local_cpu_resources=${MAKE_JOBS_NUMBER} \
	  --noshow_loading_progress \
	  --noshow_progress \
	  --subcommands \
	  --verbose_failures \
	  //tensorflow/tools/lib_package:clicenses_generate \
	  //tensorflow/tools/lib_package:libtensorflow.tar.gz

do-test:
	@cd ${WRKSRC} && ${LOCALBASE}/bin/bazel ${BAZEL_OPTS} test \
	  ${BAZEL_ARGS} \
	  --action_env=PATH=${PATH} \
	  --local_cpu_resources=${MAKE_JOBS_NUMBER} \
	  --noshow_loading_progress \
	  --noshow_progress \
	  --subcommands \
	  --test_env=CC=${CC} \
	  --verbose_failures \
	  //tensorflow/tools/lib_package:libtensorflow_test

pre-install:
	@${CP} ${WRKSRC}/bazel-bin/tensorflow/tools/lib_package/THIRD_PARTY_TF_C_LICENSES ${WRKDIR}/THIRD_PARTY_TF_C_LICENSES
	@${MKDIR} ${WRKDIR}/lib_package
	@tar xz -C ${WRKDIR}/lib_package -f ${WRKSRC}/bazel-bin/tensorflow/tools/lib_package/libtensorflow.tar.gz
	${MKDIR} ${STAGEDIR}${PREFIX}/include/tensorflow
	${MKDIR} ${STAGEDIR}${PREFIX}/include/tensorflow/c
	${MKDIR} ${STAGEDIR}${PREFIX}/include/tensorflow/c/eager

do-install:
	${INSTALL_DATA} ${WRKDIR}/lib_package/include/tensorflow/c/c_api_experimental.h ${STAGEDIR}${PREFIX}/include/tensorflow/c/c_api_experimental.h
	${INSTALL_DATA} ${WRKDIR}/lib_package/include/tensorflow/c/c_api.h ${STAGEDIR}${PREFIX}/include/tensorflow/c/c_api.h
	${INSTALL_DATA} ${WRKDIR}/lib_package/include/tensorflow/c/eager/c_api.h ${STAGEDIR}${PREFIX}/include/tensorflow/c/eager/c_api.h
	${INSTALL_DATA} ${WRKDIR}/lib_package/include/tensorflow/c/tf_attrtype.h ${STAGEDIR}${PREFIX}/include/tensorflow/c/tf_attrtype.h
	${INSTALL_DATA} ${WRKDIR}/lib_package/include/tensorflow/c/tf_datatype.h ${STAGEDIR}${PREFIX}/include/tensorflow/c/tf_datatype.h
	${INSTALL_DATA} ${WRKDIR}/lib_package/include/tensorflow/c/tf_status.h ${STAGEDIR}${PREFIX}/include/tensorflow/c/tf_status.h
	${INSTALL_DATA} ${WRKDIR}/lib_package/include/tensorflow/c/tf_tensor.h ${STAGEDIR}${PREFIX}/include/tensorflow/c/tf_tensor.h
	${INSTALL_PROGRAM} ${WRKDIR}/lib_package/lib/libtensorflow.so.${DISTVERSION} ${STAGEDIR}${PREFIX}/lib/libtensorflow.so.${DISTVERSION}
	${INSTALL_PROGRAM} ${WRKDIR}/lib_package/lib/libtensorflow_framework.so.${DISTVERSION} ${STAGEDIR}${PREFIX}/lib/libtensorflow_framework.so.${DISTVERSION}
	@${RLN} ${STAGEDIR}${PREFIX}/lib/libtensorflow.so.${DISTVERSION} ${STAGEDIR}${PREFIX}/lib/libtensorflow.so.1
	@${RLN} ${STAGEDIR}${PREFIX}/lib/libtensorflow.so.1 ${STAGEDIR}${PREFIX}/lib/libtensorflow.so
	@${RLN} ${STAGEDIR}${PREFIX}/lib/libtensorflow_framework.so.${DISTVERSION} ${STAGEDIR}${PREFIX}/lib/libtensorflow_framework.so.1
	@${RLN} ${STAGEDIR}${PREFIX}/lib/libtensorflow_framework.so.1 ${STAGEDIR}${PREFIX}/lib/libtensorflow_framework.so

.include <bsd.port.mk>

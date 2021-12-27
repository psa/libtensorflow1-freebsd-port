--- configure.py.orig   2021-12-25 17:58:29.902610000 +0000
+++ configure.py        2021-12-25 17:59:34.301740000 +0000
@@ -475,7 +475,7 @@
     print('Cannot find bazel. Please install bazel.')
     sys.exit(0)
   curr_version = run_shell(
-      ['bazel', '--batch', '--bazelrc=/dev/null', 'version'])
+      ['bazel', '--batch', '--output_user_root=/tmp/.bazel', '--bazelrc=/dev/null', 'version'])

   for line in curr_version.split('\n'):
     if 'Build label: ' in line:

# --- Custom Commands ---
arg0() {
  local argv0=$1
  local program=$2
  shift 2
  (
    exec -a "$argv0" "$program" "$@"
  )
}

complin() {
  # Linux, GCC/Clang friendly
  export CC=gcc
  export CXX=g++
  export CFLAGS="-O2 -DNDEBUG -Wall -Wextra -Wpedantic \
-fno-omit-frame-pointer \
-fstack-protector-strong \
-D_FORTIFY_SOURCE=2 \
-fPIE \
-march=x86-64 -mtune=generic"
  export CXXFLAGS="$CFLAGS"
  export LDFLAGS="-pie -Wl,-z,relro,-z,now"

  echo "Linux compilation environment loaded (gcc/g++, x86_64)"
}

compwin() {
  # Windows target via MinGW-w64
  export CC=x86_64-w64-mingw32-gcc
  export CXX=x86_64-w64-mingw32-g++
  export CFLAGS="-O2 -DNDEBUG -Wall -Wextra -Wpedantic \
-march=x86-64 -mtune=generic"
  export CXXFLAGS="$CFLAGS"
  export LDFLAGS=""

  echo "Windows compilation environment loaded (MinGW-w64, x86_64)"
}


#include <stdio.h>
#include <git2.h>

int main (int argc, char** argv)
{
  int major = 0;
  int minor = 0;
  int rev = 0;
  git_libgit2_version(&major, &minor, &rev);
  printf("Version %d.%d.%d\n", major, minor, rev);
  return 0;
};

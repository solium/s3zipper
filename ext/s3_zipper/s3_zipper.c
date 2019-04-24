#include "s3_zipper.h"

VALUE rb_mS3Zipper;

void
Init_s3_zipper(void)
{
  rb_mS3Zipper = rb_define_module("S3Zipper");
}

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing Bigints with and without intrinsics.
// VMOptions=
// VMOptions=--no_intrinsify

library big_integer_test;
import "package:expect/expect.dart";

divRemParsed(String a, String b, String quotient, String remainder) {
  int int_a = int.parse(a);
  int int_b = int.parse(b);
  int int_quotient = int.parse(quotient);
  int int_remainder = int.parse(remainder);
  int computed_quotient = int_a ~/ int_b;
  Expect.equals(int_quotient, computed_quotient);
  String str_quotient = computed_quotient >= 0 ?
      "0x${computed_quotient.toRadixString(16)}" :
      "-0x${(-computed_quotient).toRadixString(16)}";
  Expect.equals(quotient.toLowerCase(), str_quotient);
  int computed_remainder = int_a.remainder(int_b);
  Expect.equals(int_remainder, computed_remainder);
  String str_remainder = computed_remainder >= 0 ?
      "0x${computed_remainder.toRadixString(16)}" :
      "-0x${(-computed_remainder).toRadixString(16)}";
  Expect.equals(remainder.toLowerCase(), str_remainder);
}

testBigintDivideRemainder() {
  String zero = "0x0";
  String one = "0x1";
  String minus_one = "-0x1";

  divRemParsed(one, one, one, zero);
  divRemParsed(zero, one, zero, zero);
  divRemParsed(minus_one, one, minus_one, zero);
  divRemParsed(one, "0x2", zero, one);
  divRemParsed(minus_one, "0x7", zero, minus_one);
  divRemParsed("0xB", "0x7", one, "0x4");
  divRemParsed("0x12345678", "0x7", "0x299C335", "0x5");
  divRemParsed("-0x12345678", "0x7", "-0x299C335", "-0x5");
  divRemParsed("0x12345678", "-0x7", "-0x299C335", "0x5");
  divRemParsed("-0x12345678", "-0x7", "0x299C335", "-0x5");
  divRemParsed("0x7", "0x12345678", zero, "0x7");
  divRemParsed("-0x7", "0x12345678", zero, "-0x7");
  divRemParsed("-0x7", "-0x12345678", zero, "-0x7");
  divRemParsed("0x7", "-0x12345678", zero, "0x7");
  divRemParsed("0x12345678", "0x7", "0x299C335", "0x5");
  divRemParsed("-0x12345678", "0x7", "-0x299C335", "-0x5");
  divRemParsed("0x12345678", "-0x7", "-0x299C335", "0x5");
  divRemParsed("-0x12345678", "-0x7", "0x299C335", "-0x5");
  divRemParsed(
      "0x14B66DC327D3C88D7EAA988BBFFA9BBA877826E7EDAF373907A931FBFC3A25231DF7F2"
      "516F511FB1638F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A"
      "8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F"
      "0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B"
      "570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B57"
      "0F4A8F0B570F4A8F0B570F4A8F0B570F35D89D93E776C67DD864B2034B5C739007933027"
      "5CDFD41E07A15D0F5AD5256BED5F1CF91FBA375DE70",
      "0x1234567890ABCDEF01234567890ABCDEF01234567890ABCDEF01234567890ABCDEF"
      "01234567890ABCDEF",
      "0x1234567890123456789012345678901234567890123456789012345678901234567890"
      "123456789012345678901234567890123456789012345678901234567890123456789012"
      "345678901234567890123456789012345678901234567890123456789012345678901234"
      "567890123456789012345678901234567890123456789012345678901234567890123456"
      "789012345678901234567890123456789012345678901234567890123456789012345678"
      "90123456789012345678901234567890",
      zero);
  divRemParsed(
      "0x14B66DC327D3C88D7EAA988BBFFA9BBA877826E7EDAF373907A931FBFC3A25231DF7F2"
      "516F511FB1638F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A"
      "8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F"
      "0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B"
      "570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B57"
      "0F4A8F0B570F4A8F0B570F4A8F0B570F35D89D93E776C67DD864B2034B5C739007933027"
      "5CDFD41E07A15D0F5AD5256BED5F1CF91FBA375DE71",
      "0x1234567890ABCDEF01234567890ABCDEF01234567890ABCDEF01234567890ABCDEF"
      "01234567890ABCDEF",
      "0x1234567890123456789012345678901234567890123456789012345678901234567890"
      "123456789012345678901234567890123456789012345678901234567890123456789012"
      "345678901234567890123456789012345678901234567890123456789012345678901234"
      "567890123456789012345678901234567890123456789012345678901234567890123456"
      "789012345678901234567890123456789012345678901234567890123456789012345678"
      "90123456789012345678901234567890",
      one);
  divRemParsed(
      "0x14B66DC327D3C88D7EAA988BBFFA9BBA877826E7EDAF373907A931FBFC3A25231DF7F2"
      "516F511FB1638F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A"
      "8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F"
      "0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B"
      "570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B570F4A8F0B57"
      "0F4A8F0B570F4A8F0B570F4A8F0B5710591E051CF233A56DEA99087BDC08417F08B6758E"
      "E5EA90FCF7B39165D365D139DC60403E8743421AC5E",
      "0x1234567890ABCDEF01234567890ABCDEF01234567890ABCDEF01234567890ABCDEF"
      "01234567890ABCDEF",
      "0x1234567890123456789012345678901234567890123456789012345678901234567890"
      "123456789012345678901234567890123456789012345678901234567890123456789012"
      "345678901234567890123456789012345678901234567890123456789012345678901234"
      "567890123456789012345678901234567890123456789012345678901234567890123456"
      "789012345678901234567890123456789012345678901234567890123456789012345678"
      "90123456789012345678901234567890",
      "0x1234567890ABCDEF01234567890ABCDEF01234567890ABCDEF01234567890ABCDEF"
      "01234567890ABCDEE");
}

main() {
  testBigintDivideRemainder();
}
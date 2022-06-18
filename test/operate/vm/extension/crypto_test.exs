defmodule Operate.VM.Extension.CryptoTest do
  use ExUnit.Case
  alias Operate.VM
  doctest Operate.VM.Extension.Crypto

  @doc """
  Returns a generic symetric key.
  """
  def symmetric_key() do
    <<225, 142, 18, 176, 144, 89, 142, 193, 18, 237, 201, 84, 109, 62, 36, 67, 233, 244, 170, 233,
      98, 100, 18, 201, 118, 69, 91, 182, 242, 255, 173, 106>>
  end

  @doc """
  Returns a generic RSA key (erlang sequence).
  """
  def rsa_key() do
    {
      :RSAPrivateKey,
      :"two-prime",
      29_138_129_824_629_141_460_536_522_208_779_093_018_443_507_347_272_252_883_667_980_702_345_928_615_469_923_560_274_244_336_299_630_638_468_087_171_076_287_647_631_842_366_984_928_457_828_496_097_709_250_194_900_338_908_568_102_611_035_004_670_384_559_737_647_606_671_886_852_284_811_699_008_953_697_117_776_500_629_571_966_012_887_440_389_640_281_156_621_305_252_806_564_698_277_754_111_822_382_977_381_947_207_719_722_989_813_408_460_077_853_219_011_599_284_567_665_895_501_622_098_817_918_871_397_691_099_839_401_379_541_459_713_372_229_092_843_886_251_241_893_179_514_117_246_564_314_563_851_231_895_307_369_928_093_552_532_875_297_188_517_164_872_705_922_818_720_366_051_831_467_478_878_936_722_823_134_210_149_821_041_856_250_874_882_117_572_090_651_219_378_752_890_768_650_591_839_013_979_311_197_332_322_784_869_359,
      65537,
      19_656_911_299_060_127_901_082_452_963_891_256_245_043_629_504_518_071_387_044_398_779_500_407_341_610_941_307_152_370_273_227_020_916_245_038_222_799_713_588_920_747_283_658_660_862_985_999_808_839_607_696_674_150_233_083_799_268_185_599_378_779_043_214_075_651_710_903_177_033_066_738_431_479_330_103_165_153_208_639_940_207_238_346_499_027_665_448_472_483_449_609_897_286_117_095_149_181_244_124_632_049_833_416_101_124_593_839_103_743_113_016_185_986_517_261_039_420_402_367_697_842_212_005_712_466_528_790_639_695_501_124_162_677_208_339_999_360_918_927_741_566_530_930_970_293_485_729_789_354_421_830_143_580_944_599_244_293_933_294_687_482_538_472_375_122_262_288_394_688_882_204_191_234_873_214_693_554_680_360_134_522_148_315_711_339_516_295_733_784_733_781_212_460_387_660_990_914_258_099_902_330_029_990_951_777,
      179_596_775_055_365_463_620_523_845_564_192_753_603_760_746_227_886_331_695_064_930_317_452_485_069_791_913_187_130_880_037_380_678_565_612_890_702_654_350_076_122_098_200_736_556_794_234_183_771_013_047_319_197_416_554_273_260_612_825_746_643_039_326_081_599_565_182_694_060_246_100_765_207_816_852_976_701_523_625_432_633_565_935_177_515_978_219_294_149_749_667_089_301_280_947_694_226_960_596_613_300_085_613,
      162_241_943_462_773_989_354_904_743_442_407_924_663_879_353_224_926_126_901_080_480_970_360_778_495_472_270_026_246_542_341_991_204_051_680_658_472_664_165_416_063_930_591_837_885_071_904_959_715_988_658_021_116_161_437_926_435_505_588_942_314_940_662_915_985_465_144_989_988_431_059_067_045_531_518_643_155_659_183_997_600_612_887_861_880_528_762_092_704_576_887_854_013_385_317_987_493_236_577_309_604_276_043,
      106_483_236_771_996_518_301_153_471_582_279_289_970_266_129_303_705_985_789_327_219_697_960_712_457_953_589_128_467_043_130_025_802_630_941_606_940_095_519_796_571_041_850_954_733_774_105_584_307_952_057_306_285_823_505_033_738_004_982_987_279_072_571_120_934_957_418_007_279_841_657_955_562_203_632_392_628_455_735_133_372_636_396_893_247_148_414_897_123_408_499_230_800_614_519_806_438_759_905_131_498_259_405,
      134_297_621_052_413_539_657_204_745_823_079_901_507_404_840_519_081_090_960_170_819_722_616_260_625_308_988_459_249_716_580_110_179_419_253_613_096_167_940_394_831_197_196_646_374_220_146_972_849_423_512_046_439_883_452_798_742_691_040_092_339_338_328_311_172_246_191_472_937_156_057_239_851_580_623_996_712_564_735_533_909_633_467_409_542_041_973_461_817_455_659_996_526_727_499_206_608_794_895_745_437_270_107,
      164_668_798_832_932_318_753_909_061_192_015_985_565_795_384_467_503_225_893_512_793_371_809_391_754_802_450_287_175_245_180_323_241_456_918_082_979_958_834_446_549_330_126_128_708_509_874_399_989_146_272_029_116_759_011_496_469_397_600_508_106_420_358_076_182_081_722_946_081_707_775_246_180_158_034_344_181_029_933_308_111_422_051_057_528_138_601_123_824_065_800_626_860_491_221_889_514_073_445_523_433_296_655,
      :asn1_NOVALUE
    }
  end

  setup_all do
    aes_key = symmetric_key()
    ecdsa_key = Curvy.Key.generate()
    rsa_priv_key = ExPublicKey.RSAPrivateKey.from_sequence(rsa_key())
    {:ok, rsa_pub_key} = ExPublicKey.public_key_from_private_key(rsa_priv_key)
    bsv_keys = BSV.KeyPair.new()
    bsv_address = BSV.Address.from_pubkey(bsv_keys.pubkey)
    {:ok, rsa_pem_priv_key} = ExPublicKey.pem_encode(rsa_priv_key)
    {:ok, rsa_pem_pub_key} = ExPublicKey.pem_encode(rsa_pub_key)

    vm =
      VM.init()
      # binary
      |> VM.set!("aes_key", aes_key)
      # binary
      |> VM.set!("ecdsa_priv_key", Curvy.Key.to_privkey(ecdsa_key))
      # binary
      |> VM.set!("ecdsa_pub_key", Curvy.Key.to_pubkey(ecdsa_key))
      # string binary
      |> VM.set!("rsa_priv_key", rsa_pem_priv_key)
      # string binary
      |> VM.set!("rsa_pub_key", rsa_pem_pub_key)
      # struct
      |> VM.set!("bsv_priv_key", bsv_keys.privkey)
      # struct
      |> VM.set!("bsv_pub_key", bsv_keys.pubkey)
      # string binary
      |> VM.set!("bsv_address", BSV.Address.to_string(bsv_address))

    %{
      vm: vm
    }
  end

  describe "Operate.VM.Extension.Crypto.aes_encrypt/3 and Operate.VM.Extension.Crypto.aes_decrypt/3" do
    test "must encrypt with public key and decrypt with private key", ctx do
      script = """
      function dump(o)
      if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
      else
      return tostring(o)
      end
      end

      enc_data = crypto.aes.encrypt('hello world', aes_key)
      return crypto.aes.decrypt(enc_data, aes_key)
      """

      assert VM.eval!(ctx.vm, script) == "hello world"
    end
  end

  describe "Operate.VM.Extension.Crypto.ecdsa_sign/3 and Operate.VM.Extension.Crypto.ecdsa_verify/4" do
    test "must sign and verify message", ctx do
      script = """
      sig = crypto.ecdsa.sign('hello world', ecdsa_priv_key)
      return crypto.ecdsa.verify(sig, 'hello world', ecdsa_pub_key)
      """

      assert VM.eval!(ctx.vm, script) == true
    end

    test "wont verify when different message", ctx do
      script = """
      sig = crypto.ecdsa.sign('hello world', ecdsa_priv_key)
      return crypto.ecdsa.verify(sig, 'goodbye world', ecdsa_pub_key)
      """

      assert VM.eval!(ctx.vm, script) == false
    end
  end

  describe "Operate.VM.Extension.Crypto.rsa_encrypt/3 and Operate.VM.Extension.Crypto.rsa_decrypt/3" do
    @tag :rsa
    test "must encrypt with public key and decrypt with private key", ctx do
      script = """
      enc_data = crypto.rsa.encrypt('hello world', rsa_pub_key)
      return crypto.rsa.decrypt(enc_data, rsa_priv_key)
      """

      assert VM.eval!(ctx.vm, script) == "hello world"
    end

    @tag :rsa
    test "must encrypt with private key and decrypt with public key", ctx do
      script = """
      enc_data = crypto.rsa.encrypt('hello world', rsa_priv_key)
      return crypto.rsa.decrypt(enc_data, rsa_pub_key)
      """

      assert VM.eval!(ctx.vm, script) == "hello world"
    end
  end

  describe "Operate.VM.Extension.Crypto.rsa_sign/3 and Operate.VM.Extension.Crypto.rsa_verify/4" do
    @tag :rsa
    test "must sign and verify message", ctx do
      script = """
      sig = crypto.rsa.sign('hello world', rsa_priv_key)
      return crypto.rsa.verify(sig, 'hello world', rsa_pub_key)
      """

      assert VM.eval!(ctx.vm, script) == true
    end

    @tag :rsa
    test "wont verify when different message", ctx do
      script = """
      sig = crypto.rsa.sign('hello world', rsa_priv_key)
      return crypto.rsa.verify(sig, 'goodbye world', rsa_pub_key)
      """

      assert VM.eval!(ctx.vm, script) == false
    end
  end

  describe "Operate.VM.Extension.Crypto.hash functions" do
    test "must create a ripemd160 hash", ctx do
      assert VM.eval!(ctx.vm, "return crypto.hash.ripemd160('hello world')") == <<
               152,
               198,
               21,
               120,
               76,
               203,
               95,
               229,
               147,
               111,
               188,
               12,
               190,
               157,
               253,
               180,
               8,
               217,
               47,
               15
             >>
    end

    test "must create a sha1 hash", ctx do
      assert VM.eval!(ctx.vm, "return crypto.hash.sha1('hello world')") == <<
               42,
               174,
               108,
               53,
               201,
               79,
               207,
               180,
               21,
               219,
               233,
               95,
               64,
               139,
               156,
               233,
               30,
               232,
               70,
               237
             >>
    end

    test "must create a sha256 hash", ctx do
      assert VM.eval!(ctx.vm, "return crypto.hash.sha256('hello world')") == <<
               185,
               77,
               39,
               185,
               147,
               77,
               62,
               8,
               165,
               46,
               82,
               215,
               218,
               125,
               171,
               250,
               196,
               132,
               239,
               227,
               122,
               83,
               128,
               238,
               144,
               136,
               247,
               172,
               226,
               239,
               205,
               233
             >>
    end

    test "must create a sha512 hash", ctx do
      assert VM.eval!(ctx.vm, "return crypto.hash.sha512('hello world')") == <<
               48,
               158,
               204,
               72,
               156,
               18,
               214,
               235,
               76,
               196,
               15,
               80,
               201,
               2,
               242,
               180,
               208,
               237,
               119,
               238,
               81,
               26,
               124,
               122,
               155,
               205,
               60,
               168,
               109,
               76,
               216,
               111,
               152,
               157,
               211,
               91,
               197,
               255,
               73,
               150,
               112,
               218,
               52,
               37,
               91,
               69,
               176,
               207,
               216,
               48,
               232,
               31,
               96,
               93,
               207,
               125,
               197,
               84,
               46,
               147,
               174,
               156,
               215,
               111
             >>
    end
  end

  describe "Operate.VM.Extension.Crypto.bitcoin_message_sign/3 and Operate.VM.Extension.Crypto.bitcoin_message_verify/4" do
    test "must sign and verify message", ctx do
      script = """
      sig = crypto.bitcoin_message.sign('hello world', bsv_priv_key)
      return crypto.bitcoin_message.verify(sig, 'hello world', bsv_pub_key)
      """

      assert VM.eval!(ctx.vm, script) == true
    end

    test "must verify message with address", ctx do
      script = """
      sig = crypto.bitcoin_message.sign('hello world', bsv_priv_key)
      return crypto.bitcoin_message.verify(sig, 'hello world', bsv_address)
      """

      assert VM.eval!(ctx.vm, script) == true
    end

    test "wont verify when different message", ctx do
      script = """
      sig = crypto.bitcoin_message.sign('hello world', bsv_priv_key)
      return crypto.bitcoin_message.verify(sig, 'goodbye world', bsv_pub_key)
      """

      assert VM.eval!(ctx.vm, script) == false
    end
  end
end

// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from Random Forest model with 100 trees

class PoseClassifier {
  static const Map<int, String> labels = {0: 'sitting_floor', 1: 'walking_normal'};

  /// Predicts the label index from normalized landmarks (x, y, z, visibility)
  int predict(List<double> features) {
    if (features.length < 33 * 4) return -1;
    
    List<int> votes = List.filled(labels.length, 0);
    
    votes[_predictTree0(features)]++;
    votes[_predictTree1(features)]++;
    votes[_predictTree2(features)]++;
    votes[_predictTree3(features)]++;
    votes[_predictTree4(features)]++;
    votes[_predictTree5(features)]++;
    votes[_predictTree6(features)]++;
    votes[_predictTree7(features)]++;
    votes[_predictTree8(features)]++;
    votes[_predictTree9(features)]++;
    votes[_predictTree10(features)]++;
    votes[_predictTree11(features)]++;
    votes[_predictTree12(features)]++;
    votes[_predictTree13(features)]++;
    votes[_predictTree14(features)]++;
    votes[_predictTree15(features)]++;
    votes[_predictTree16(features)]++;
    votes[_predictTree17(features)]++;
    votes[_predictTree18(features)]++;
    votes[_predictTree19(features)]++;
    votes[_predictTree20(features)]++;
    votes[_predictTree21(features)]++;
    votes[_predictTree22(features)]++;
    votes[_predictTree23(features)]++;
    votes[_predictTree24(features)]++;
    votes[_predictTree25(features)]++;
    votes[_predictTree26(features)]++;
    votes[_predictTree27(features)]++;
    votes[_predictTree28(features)]++;
    votes[_predictTree29(features)]++;
    votes[_predictTree30(features)]++;
    votes[_predictTree31(features)]++;
    votes[_predictTree32(features)]++;
    votes[_predictTree33(features)]++;
    votes[_predictTree34(features)]++;
    votes[_predictTree35(features)]++;
    votes[_predictTree36(features)]++;
    votes[_predictTree37(features)]++;
    votes[_predictTree38(features)]++;
    votes[_predictTree39(features)]++;
    votes[_predictTree40(features)]++;
    votes[_predictTree41(features)]++;
    votes[_predictTree42(features)]++;
    votes[_predictTree43(features)]++;
    votes[_predictTree44(features)]++;
    votes[_predictTree45(features)]++;
    votes[_predictTree46(features)]++;
    votes[_predictTree47(features)]++;
    votes[_predictTree48(features)]++;
    votes[_predictTree49(features)]++;
    votes[_predictTree50(features)]++;
    votes[_predictTree51(features)]++;
    votes[_predictTree52(features)]++;
    votes[_predictTree53(features)]++;
    votes[_predictTree54(features)]++;
    votes[_predictTree55(features)]++;
    votes[_predictTree56(features)]++;
    votes[_predictTree57(features)]++;
    votes[_predictTree58(features)]++;
    votes[_predictTree59(features)]++;
    votes[_predictTree60(features)]++;
    votes[_predictTree61(features)]++;
    votes[_predictTree62(features)]++;
    votes[_predictTree63(features)]++;
    votes[_predictTree64(features)]++;
    votes[_predictTree65(features)]++;
    votes[_predictTree66(features)]++;
    votes[_predictTree67(features)]++;
    votes[_predictTree68(features)]++;
    votes[_predictTree69(features)]++;
    votes[_predictTree70(features)]++;
    votes[_predictTree71(features)]++;
    votes[_predictTree72(features)]++;
    votes[_predictTree73(features)]++;
    votes[_predictTree74(features)]++;
    votes[_predictTree75(features)]++;
    votes[_predictTree76(features)]++;
    votes[_predictTree77(features)]++;
    votes[_predictTree78(features)]++;
    votes[_predictTree79(features)]++;
    votes[_predictTree80(features)]++;
    votes[_predictTree81(features)]++;
    votes[_predictTree82(features)]++;
    votes[_predictTree83(features)]++;
    votes[_predictTree84(features)]++;
    votes[_predictTree85(features)]++;
    votes[_predictTree86(features)]++;
    votes[_predictTree87(features)]++;
    votes[_predictTree88(features)]++;
    votes[_predictTree89(features)]++;
    votes[_predictTree90(features)]++;
    votes[_predictTree91(features)]++;
    votes[_predictTree92(features)]++;
    votes[_predictTree93(features)]++;
    votes[_predictTree94(features)]++;
    votes[_predictTree95(features)]++;
    votes[_predictTree96(features)]++;
    votes[_predictTree97(features)]++;
    votes[_predictTree98(features)]++;
    votes[_predictTree99(features)]++;

    int maxVotes = -1;
    int bestClass = 0;
    for (int i = 0; i < votes.length; i++) {
      if (votes[i] > maxVotes) {
        maxVotes = votes[i];
        bestClass = i;
      }
    }
    return bestClass;
  }

  String predictLabel(List<double> features) {
    int index = predict(features);
    if (index == -1) return 'unknown';
    return labels[index] ?? 'unknown';
  }

  int _predictTree0(List<double> features) {
    if (features[29] <= 0.433674) {
      return 0;
    } else {
      if (features[130] <= -0.399056) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree1(List<double> features) {
    if (features[25] <= 0.430120) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree2(List<double> features) {
    if (features[21] <= 0.430929) {
      return 0;
    } else {
      if (features[49] <= 0.482254) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree3(List<double> features) {
    if (features[41] <= 0.461080) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree4(List<double> features) {
    if (features[25] <= 0.429701) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree5(List<double> features) {
    if (features[25] <= 0.430095) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree6(List<double> features) {
    if (features[10] <= -0.455011) {
      if (features[110] <= -0.168752) {
        return 0;
      } else {
        return 1;
      }
    } else {
      if (features[113] <= 0.696954) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree7(List<double> features) {
    if (features[124] <= 0.301204) {
      if (features[130] <= -0.068767) {
        return 0;
      } else {
        return 1;
      }
    } else {
      if (features[38] <= -0.498654) {
        if (features[69] <= 0.665620) {
          return 0;
        } else {
          return 1;
        }
      } else {
        if (features[21] <= 0.429433) {
          return 0;
        } else {
          return 1;
        }
      }
    }
  }
  int _predictTree8(List<double> features) {
    if (features[1] <= 0.446337) {
      return 0;
    } else {
      if (features[30] <= -0.420334) {
        return 0;
      } else {
        if (features[33] <= 0.427758) {
          return 0;
        } else {
          return 1;
        }
      }
    }
  }
  int _predictTree9(List<double> features) {
    if (features[21] <= 0.431176) {
      return 0;
    } else {
      if (features[45] <= 0.485155) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree10(List<double> features) {
    if (features[21] <= 0.431176) {
      return 0;
    } else {
      if (features[105] <= 0.651615) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree11(List<double> features) {
    if (features[37] <= 0.460614) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree12(List<double> features) {
    if (features[25] <= 0.430095) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree13(List<double> features) {
    if (features[1] <= 0.446343) {
      return 0;
    } else {
      if (features[29] <= 0.427677) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree14(List<double> features) {
    if (features[102] <= -0.461470) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree15(List<double> features) {
    if (features[17] <= 0.431219) {
      return 0;
    } else {
      if (features[49] <= 0.482663) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree16(List<double> features) {
    if (features[5] <= 0.429414) {
      return 0;
    } else {
      if (features[105] <= 0.651615) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree17(List<double> features) {
    if (features[21] <= 0.431176) {
      return 0;
    } else {
      if (features[57] <= 0.568860) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree18(List<double> features) {
    if (features[33] <= 0.433808) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree19(List<double> features) {
    if (features[46] <= -0.223919) {
      if (features[110] <= -0.262531) {
        return 0;
      } else {
        return 1;
      }
    } else {
      if (features[41] <= 0.423213) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree20(List<double> features) {
    if (features[25] <= 0.429701) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree21(List<double> features) {
    if (features[106] <= -0.354581) {
      return 0;
    } else {
      if (features[29] <= 0.397629) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree22(List<double> features) {
    if (features[106] <= -0.315032) {
      if (features[107] <= 0.764312) {
        return 1;
      } else {
        return 0;
      }
    } else {
      return 1;
    }
  }
  int _predictTree23(List<double> features) {
    if (features[37] <= 0.460678) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree24(List<double> features) {
    if (features[29] <= 0.433764) {
      return 0;
    } else {
      if (features[44] <= 0.717733) {
        return 1;
      } else {
        if (features[115] <= 0.531397) {
          return 1;
        } else {
          return 0;
        }
      }
    }
  }
  int _predictTree25(List<double> features) {
    if (features[118] <= -0.276771) {
      if (features[2] <= -0.283606) {
        return 0;
      } else {
        return 1;
      }
    } else {
      return 1;
    }
  }
  int _predictTree26(List<double> features) {
    if (features[30] <= -0.288696) {
      if (features[45] <= 0.528641) {
        return 0;
      } else {
        return 1;
      }
    } else {
      if (features[53] <= 0.561786) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree27(List<double> features) {
    if (features[44] <= 0.701673) {
      if (features[1] <= 0.421488) {
        return 0;
      } else {
        return 1;
      }
    } else {
      if (features[53] <= 0.655573) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree28(List<double> features) {
    if (features[41] <= 0.461096) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree29(List<double> features) {
    if (features[5] <= 0.429376) {
      return 0;
    } else {
      if (features[5] <= 0.435288) {
        if (features[51] <= 0.999881) {
          return 1;
        } else {
          return 0;
        }
      } else {
        return 1;
      }
    }
  }
  int _predictTree30(List<double> features) {
    if (features[49] <= 0.504310) {
      return 0;
    } else {
      if (features[49] <= 0.512182) {
        if (features[33] <= 0.440188) {
          return 0;
        } else {
          return 1;
        }
      } else {
        return 1;
      }
    }
  }
  int _predictTree31(List<double> features) {
    if (features[29] <= 0.434474) {
      if (features[67] <= 0.945839) {
        return 1;
      } else {
        return 0;
      }
    } else {
      return 1;
    }
  }
  int _predictTree32(List<double> features) {
    if (features[110] <= -0.303225) {
      if (features[112] <= 0.479998) {
        return 1;
      } else {
        return 0;
      }
    } else {
      return 1;
    }
  }
  int _predictTree33(List<double> features) {
    if (features[21] <= 0.431176) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree34(List<double> features) {
    if (features[41] <= 0.460962) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree35(List<double> features) {
    if (features[17] <= 0.430708) {
      return 0;
    } else {
      if (features[25] <= 0.429528) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree36(List<double> features) {
    if (features[103] <= 0.988762) {
      if (features[41] <= 0.434350) {
        return 0;
      } else {
        return 1;
      }
    } else {
      if (features[84] <= 0.495033) {
        return 1;
      } else {
        return 0;
      }
    }
  }
  int _predictTree37(List<double> features) {
    if (features[5] <= 0.429414) {
      return 0;
    } else {
      if (features[102] <= -0.557303) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree38(List<double> features) {
    if (features[29] <= 0.434745) {
      if (features[70] <= 0.032431) {
        return 0;
      } else {
        return 1;
      }
    } else {
      return 1;
    }
  }
  int _predictTree39(List<double> features) {
    if (features[10] <= -0.474565) {
      if (features[122] <= -0.108833) {
        return 0;
      } else {
        return 1;
      }
    } else {
      if (features[13] <= 0.400590) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree40(List<double> features) {
    if (features[9] <= 0.428871) {
      return 0;
    } else {
      if (features[105] <= 0.651936) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree41(List<double> features) {
    if (features[41] <= 0.461096) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree42(List<double> features) {
    if (features[33] <= 0.433819) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree43(List<double> features) {
    if (features[5] <= 0.429383) {
      return 0;
    } else {
      if (features[25] <= 0.430095) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree44(List<double> features) {
    if (features[5] <= 0.429376) {
      return 0;
    } else {
      if (features[110] <= -0.464603) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree45(List<double> features) {
    if (features[103] <= 0.991718) {
      if (features[110] <= -0.315955) {
        if (features[79] <= 0.977461) {
          return 0;
        } else {
          return 1;
        }
      } else {
        if (features[93] <= 0.611170) {
          return 0;
        } else {
          return 1;
        }
      }
    } else {
      return 0;
    }
  }
  int _predictTree46(List<double> features) {
    if (features[102] <= -0.469801) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree47(List<double> features) {
    if (features[57] <= 0.579937) {
      return 0;
    } else {
      if (features[110] <= -0.401538) {
        if (features[36] <= 0.494612) {
          return 1;
        } else {
          return 0;
        }
      } else {
        return 1;
      }
    }
  }
  int _predictTree48(List<double> features) {
    if (features[118] <= -0.276912) {
      if (features[47] <= 0.999990) {
        return 0;
      } else {
        return 1;
      }
    } else {
      return 1;
    }
  }
  int _predictTree49(List<double> features) {
    if (features[122] <= -0.167000) {
      if (features[125] <= 0.807682) {
        return 0;
      } else {
        return 1;
      }
    } else {
      if (features[122] <= -0.122509) {
        if (features[97] <= 0.625379) {
          return 0;
        } else {
          return 1;
        }
      } else {
        return 1;
      }
    }
  }
  int _predictTree50(List<double> features) {
    if (features[46] <= -0.256722) {
      if (features[40] <= 0.473111) {
        return 1;
      } else {
        return 0;
      }
    } else {
      if (features[25] <= 0.428336) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree51(List<double> features) {
    if (features[102] <= -0.461470) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree52(List<double> features) {
    if (features[25] <= 0.430095) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree53(List<double> features) {
    if (features[9] <= 0.428871) {
      return 0;
    } else {
      if (features[45] <= 0.485821) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree54(List<double> features) {
    if (features[122] <= -0.185304) {
      if (features[5] <= 0.441623) {
        return 0;
      } else {
        return 1;
      }
    } else {
      if (features[57] <= 0.564473) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree55(List<double> features) {
    if (features[37] <= 0.460617) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree56(List<double> features) {
    if (features[109] <= 0.780340) {
      if (features[102] <= -0.452013) {
        return 0;
      } else {
        return 1;
      }
    } else {
      if (features[25] <= 0.428867) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree57(List<double> features) {
    if (features[102] <= -0.461470) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree58(List<double> features) {
    if (features[106] <= -0.312845) {
      if (features[88] <= 0.586848) {
        return 0;
      } else {
        return 1;
      }
    } else {
      return 1;
    }
  }
  int _predictTree59(List<double> features) {
    if (features[37] <= 0.460617) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree60(List<double> features) {
    if (features[45] <= 0.504065) {
      return 0;
    } else {
      if (features[1] <= 0.446281) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree61(List<double> features) {
    if (features[57] <= 0.578934) {
      return 0;
    } else {
      if (features[13] <= 0.428404) {
        if (features[89] <= 0.745889) {
          return 0;
        } else {
          return 1;
        }
      } else {
        if (features[17] <= 0.430296) {
          return 0;
        } else {
          return 1;
        }
      }
    }
  }
  int _predictTree62(List<double> features) {
    if (features[37] <= 0.460617) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree63(List<double> features) {
    if (features[44] <= 0.701673) {
      if (features[102] <= -0.461470) {
        return 0;
      } else {
        return 1;
      }
    } else {
      if (features[65] <= 0.775792) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree64(List<double> features) {
    if (features[6] <= -0.478920) {
      if (features[130] <= -0.258446) {
        return 0;
      } else {
        return 1;
      }
    } else {
      if (features[113] <= 0.699512) {
        return 0;
      } else {
        if (features[9] <= 0.418851) {
          return 0;
        } else {
          return 1;
        }
      }
    }
  }
  int _predictTree65(List<double> features) {
    if (features[102] <= -0.469801) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree66(List<double> features) {
    if (features[44] <= 0.701673) {
      if (features[129] <= 0.713429) {
        return 0;
      } else {
        return 1;
      }
    } else {
      if (features[57] <= 0.670452) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree67(List<double> features) {
    if (features[45] <= 0.503676) {
      return 0;
    } else {
      if (features[5] <= 0.429357) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree68(List<double> features) {
    if (features[17] <= 0.430708) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree69(List<double> features) {
    if (features[41] <= 0.461036) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree70(List<double> features) {
    if (features[114] <= -0.166885) {
      if (features[55] <= 0.904652) {
        return 1;
      } else {
        return 0;
      }
    } else {
      if (features[5] <= 0.384883) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree71(List<double> features) {
    if (features[21] <= 0.431626) {
      if (features[105] <= 0.889394) {
        return 0;
      } else {
        return 1;
      }
    } else {
      return 1;
    }
  }
  int _predictTree72(List<double> features) {
    if (features[6] <= -0.477922) {
      if (features[17] <= 0.437576) {
        return 0;
      } else {
        return 1;
      }
    } else {
      if (features[102] <= -0.459047) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree73(List<double> features) {
    if (features[102] <= -0.461470) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree74(List<double> features) {
    if (features[25] <= 0.430095) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree75(List<double> features) {
    if (features[110] <= -0.312638) {
      if (features[50] <= -0.022542) {
        return 0;
      } else {
        return 1;
      }
    } else {
      return 1;
    }
  }
  int _predictTree76(List<double> features) {
    if (features[46] <= -0.226978) {
      if (features[110] <= -0.277929) {
        return 0;
      } else {
        return 1;
      }
    } else {
      if (features[113] <= 0.691177) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree77(List<double> features) {
    if (features[118] <= -0.276912) {
      if (features[56] <= 0.374422) {
        return 1;
      } else {
        return 0;
      }
    } else {
      return 1;
    }
  }
  int _predictTree78(List<double> features) {
    if (features[17] <= 0.431219) {
      return 0;
    } else {
      if (features[30] <= -0.386899) {
        if (features[73] <= 0.655817) {
          return 0;
        } else {
          return 1;
        }
      } else {
        return 1;
      }
    }
  }
  int _predictTree79(List<double> features) {
    if (features[25] <= 0.430095) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree80(List<double> features) {
    if (features[106] <= -0.328225) {
      if (features[103] <= 0.706892) {
        return 1;
      } else {
        return 0;
      }
    } else {
      return 1;
    }
  }
  int _predictTree81(List<double> features) {
    if (features[29] <= 0.434745) {
      if (features[111] <= 0.381741) {
        return 1;
      } else {
        return 0;
      }
    } else {
      return 1;
    }
  }
  int _predictTree82(List<double> features) {
    if (features[13] <= 0.428280) {
      return 0;
    } else {
      if (features[29] <= 0.434470) {
        if (features[126] <= 0.181827) {
          return 0;
        } else {
          return 1;
        }
      } else {
        return 1;
      }
    }
  }
  int _predictTree83(List<double> features) {
    if (features[17] <= 0.431219) {
      return 0;
    } else {
      if (features[29] <= 0.427272) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree84(List<double> features) {
    if (features[102] <= -0.471449) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree85(List<double> features) {
    if (features[30] <= -0.298362) {
      if (features[1] <= 0.462159) {
        return 0;
      } else {
        return 1;
      }
    } else {
      if (features[102] <= -0.471449) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree86(List<double> features) {
    if (features[9] <= 0.428866) {
      return 0;
    } else {
      if (features[102] <= -0.546652) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree87(List<double> features) {
    if (features[104] <= 0.310442) {
      return 0;
    } else {
      if (features[63] <= 0.944307) {
        return 1;
      } else {
        if (features[130] <= -0.364686) {
          return 0;
        } else {
          return 1;
        }
      }
    }
  }
  int _predictTree88(List<double> features) {
    if (features[102] <= -0.461470) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree89(List<double> features) {
    if (features[41] <= 0.461096) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree90(List<double> features) {
    if (features[41] <= 0.461131) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree91(List<double> features) {
    if (features[25] <= 0.430095) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree92(List<double> features) {
    if (features[130] <= -0.276783) {
      if (features[6] <= -0.410434) {
        return 0;
      } else {
        return 1;
      }
    } else {
      if (features[29] <= 0.400653) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree93(List<double> features) {
    if (features[9] <= 0.428871) {
      return 0;
    } else {
      if (features[121] <= 0.710792) {
        return 0;
      } else {
        if (features[21] <= 0.430453) {
          return 0;
        } else {
          return 1;
        }
      }
    }
  }
  int _predictTree94(List<double> features) {
    if (features[33] <= 0.433815) {
      return 0;
    } else {
      return 1;
    }
  }
  int _predictTree95(List<double> features) {
    if (features[1] <= 0.446631) {
      return 0;
    } else {
      if (features[33] <= 0.428032) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree96(List<double> features) {
    if (features[126] <= -0.369723) {
      if (features[24] <= 0.453005) {
        return 1;
      } else {
        return 0;
      }
    } else {
      if (features[97] <= 0.608414) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree97(List<double> features) {
    if (features[17] <= 0.430708) {
      return 0;
    } else {
      if (features[41] <= 0.459964) {
        return 0;
      } else {
        return 1;
      }
    }
  }
  int _predictTree98(List<double> features) {
    if (features[110] <= -0.310364) {
      if (features[40] <= 0.450485) {
        return 1;
      } else {
        return 0;
      }
    } else {
      return 1;
    }
  }
  int _predictTree99(List<double> features) {
    if (features[13] <= 0.427968) {
      return 0;
    } else {
      if (features[21] <= 0.431187) {
        return 0;
      } else {
        return 1;
      }
    }
  }
}

#include "GumboParser.hpp"
#include <jni.h>
#include <string>

extern "C" JNIEXPORT jstring JNICALL
Java_com_swmansion_enriched_common_GumboNormalizer_normalizeHtml(
    JNIEnv *env, jclass /*cls*/, jstring htmlJString) {
  const char *htmlChars = env->GetStringUTFChars(htmlJString, nullptr);
  std::string result = GumboParser::normalizeHtml(htmlChars);
  env->ReleaseStringUTFChars(htmlJString, htmlChars);
  if (result.empty())
    return nullptr;
  return env->NewStringUTF(result.c_str());
}

#include <gtest/gtest.h>

#include "toporoom/app/evidence_pack.hpp"

using toporoom::app::EvidenceItem;
using toporoom::app::EvidencePack;

TEST(EvidencePack, EmptyUntilAttach) {
  EvidencePack pack("doc_1");
  EXPECT_TRUE(pack.empty());
  pack.attach({"note_1", "note", ""});
  EXPECT_FALSE(pack.empty());
  EXPECT_EQ(pack.items().size(), 1u);
  EXPECT_TRUE(pack.detach("note_1"));
  EXPECT_TRUE(pack.empty());
}

TEST(EvidencePack, DetachAllClearsSidecar) {
  EvidencePack pack("doc_1");
  pack.attach({"a", "note", ""});
  pack.attach({"b", "thumbnail", "file://x"});
  pack.detach_all();
  EXPECT_TRUE(pack.empty());
}

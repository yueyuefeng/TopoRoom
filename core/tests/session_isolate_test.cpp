#include <chrono>
#include <stdexcept>
#include <thread>
#include <vector>

#include <gtest/gtest.h>

#include "toporoom/app/session_isolate.hpp"

using toporoom::app::SessionIsolate;
using namespace std::chrono_literals;

TEST(SessionIsolate, SerializesWritesOnSameDocument) {
  SessionIsolate isolate;
  std::vector<int> log;

  std::thread first([&] {
    isolate.enqueue("doc_1", [&] {
      std::this_thread::sleep_for(40ms);
      log.push_back(1);
    });
  });
  std::this_thread::sleep_for(10ms);
  std::thread second([&] {
    isolate.enqueue("doc_1", [&] { log.push_back(2); });
  });
  first.join();
  second.join();
  EXPECT_EQ(log, (std::vector<int>{1, 2}));
}

TEST(SessionIsolate, PreventsLostUpdateOnSameDocument) {
  SessionIsolate isolate;
  int shared = 0;
  std::thread slow([&] {
    isolate.enqueue("doc_1", [&] {
      const int snapshot = shared;
      std::this_thread::sleep_for(30ms);
      shared = snapshot + 1;
    });
  });
  std::this_thread::sleep_for(5ms);
  std::thread fast([&] { isolate.enqueue("doc_1", [&] { shared += 1; }); });
  slow.join();
  fast.join();
  EXPECT_EQ(shared, 2);
}

TEST(SessionIsolate, AllowsParallelDifferentDocuments) {
  SessionIsolate isolate;
  bool other_started = false;
  std::thread first([&] { isolate.enqueue("doc_a", [&] { std::this_thread::sleep_for(40ms); }); });
  std::thread second([&] { isolate.enqueue("doc_b", [&] { other_started = true; }); });
  second.join();
  first.join();
  EXPECT_TRUE(other_started);
}

TEST(SessionIsolate, ErrorDoesNotStallQueue) {
  SessionIsolate isolate;
  EXPECT_THROW(isolate.enqueue("doc_1", [] { throw std::runtime_error("boom"); }),
               std::runtime_error);
  EXPECT_EQ(isolate.enqueue("doc_1", [] { return std::string("ok"); }), "ok");
}

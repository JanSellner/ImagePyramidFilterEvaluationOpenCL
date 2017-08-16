#pragma once

#include <sstream>
#include <iostream>
#include <filesystem>

/**
* @def IPU_OUTPUT_TARGET
* Specifies where the output from the other macros should be passed to.
* 0 = normal console window
* 1 = visual studio output window
*/
#define IPU_OUTPUT_TARGET 0

#if IPU_OUTPUT_TARGET == 0
#define IPU_DETAIL_PRINT(str) std::cout << str
#elif IPU_OUTPUT_TARGET == 1
#define IPU_DETAIL_PRINT(str) OutputDebugStringA(str.c_str())
#endif

#define IPU_DETAIL_ASSERT1(msgExpr) { std::stringstream _s; \
									  _s << "EXCEPTION! " << std::endl \
									     << std::experimental::filesystem::path(__FILE__).filename() << "(" << __LINE__ << "): Assert failed (" << msgExpr << ")" \
									     << std::endl << std::endl; \
									  IPU_DETAIL_PRINT(_s.str()); \
									  throw std::string(_s.str()); }

#define IPU_DETAIL_ASSERT2(cond, msgExpr) if(!(cond)) { \
										      std::stringstream _s; \
											  _s << "EXCEPTION! " << std::endl \
											     << std::experimental::filesystem::path(__FILE__).filename() << "(" << __LINE__ << "): The condition " << #cond << " fails (" << msgExpr << ")" \
											     << std::endl << std::endl; \
											  IPU_DETAIL_PRINT(_s.str()); \
											  throw std::string(_s.str()); }


#define IPU_DETAIL_ASSERT_N_ARGS_IMPL2(_1, _2, count, ...) count								// Allows macro overloading for the assert macro based on http://stackoverflow.com/questions/11974170/overloading-a-macro
#define IPU_DETAIL_ASSERT_N_ARGS_IMPL(args) IPU_DETAIL_ASSERT_N_ARGS_IMPL2 args
#define IPU_DETAIL_ASSERT_N_ARGS(...) IPU_DETAIL_ASSERT_N_ARGS_IMPL((__VA_ARGS__, 2, 1, 0))
/* Pick the right helper macro to invoke. */
#define IPU_DETAIL_ASSERT_CHOOSER2(count) IPU_DETAIL_ASSERT##count
#define IPU_DETAIL_ASSERT_CHOOSER1(count) IPU_DETAIL_ASSERT_CHOOSER2(count)
#define IPU_DETAIL_ASSERT_CHOOSER(count)  IPU_DETAIL_ASSERT_CHOOSER1(count)
/* The actual macro. */
#define IPU_DETAIL_ASSERT_GLUE(x, y) x y

/**
* @def ASSERT(cond, msgExpr)
* Use this macro to check conditions at runtime in release and debug mode.
* Type in the condition the behavior you desire (the assertion fails if your condition fails).
*
* If only the <code>msgExpr</code> is supplied the macro always fails and throws an exception with the given message.
* Use it when you want to prohibit that certain code is reached. E. g. when you want to make sure that you never reach
* the <code>default</code> block in a <code>switch</code> statement.
*/
#define ASSERT(...) IPU_DETAIL_ASSERT_GLUE(IPU_DETAIL_ASSERT_CHOOSER(IPU_DETAIL_ASSERT_N_ARGS(__VA_ARGS__)), (__VA_ARGS__))

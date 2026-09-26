/*
 * BEGIN illumos section
 *   This is an unstable interface; changes may be made
 *   without notice.
 * END illumos section
 */
/***********************************************************************
*                                                                      *
*               This software is part of the ast package               *
*          Copyright (c) 1985-2025 AT&T Intellectual Property          *
*                         All Rights Reserved                          *
*       This software is licensed by AT&T Intellectual Property        *
*           under the terms and conditions of the license in           *
*          http://www.eclipse.org/org/documents/epl-v10.html           *
*      (with an md5 checksum of b35adb5213ca9657e911e9befb180842)      *
*                                                                      *
*              Information and Software Systems Research               *
*                            AT&T Research                             *
*                           Florham Park NJ                            *
*                                                                      *
*                 Glenn Fowler <gsf@research.att.com>                  *
*                  David Korn <dgk@research.att.com>                   *
*                   Phong Vo <kpv@research.att.com>                    *
*                                                                      *
***********************************************************************/
/* : : generated from contrib/ast/src/lib/libast/features/standards by iffe version 2012-07-17 : : */
#ifndef _def_standards_ast
#define _def_standards_ast	1
#define _sys_types	1	/* #include <sys/types.h> ok */
/* _ALL_SOURCE & _POSIX_SOURCE & _POSIX_C_SOURCE & _XOPEN_SOURCE & __EXTENSIONS__ works */
#ifndef _ALL_SOURCE
#define _ALL_SOURCE	1
#endif
#ifndef _POSIX_SOURCE
#define _POSIX_SOURCE	1
#endif
#ifndef _POSIX_C_SOURCE
#define _POSIX_C_SOURCE	21000101L
#endif
#ifndef _XOPEN_SOURCE
#define _XOPEN_SOURCE	9900
#endif
#ifndef _GNU_SOURCE
#define _GNU_SOURCE	1
#endif
#ifndef __EXTENSIONS__
#define __EXTENSIONS__	1
#endif

#define _LIB_m	1	/* -lm is a library */
/* _ISOC99_SOURCE plays nice */
#ifndef _ISOC99_SOURCE
#define _ISOC99_SOURCE	1
#endif


/*
* this is a nasty game we all play to honor standards symbol visibility
* it would help if all implementations had
*	_KITCHEN_SINK_SOURCE
* that enabled all symbols from the latest implemented standards
* that's probably the most useful but least portable request
*/

#if __MACH__
#undef  _POSIX_SOURCE
#endif


#endif

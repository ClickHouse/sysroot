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
/* : : generated from contrib/ast/src/lib/libast/features/align.c by iffe version 2012-07-17 : : */
#ifndef _def_align_ast
#define _def_align_ast	1
#define _sys_types	1	/* #include <sys/types.h> ok */

#define ALIGN_CHUNK		8192
#define ALIGN_INTEGRAL		uintptr_t
#define ALIGN_INTEGER(x)	((char*)(x)-(char*)0)
#define ALIGN_POINTER(x)	((char*)(x))
#define ALIGN_ROUND(x,y)	ALIGN_POINTER(ALIGN_INTEGER((x)+(y)-1)&~((y)-1))

#define ALIGN_BOUND		ALIGN_BOUND2
#define ALIGN_ALIGN(x)		ALIGN_ALIGN2(x)
#define ALIGN_TRUNC(x)		ALIGN_TRUNC2(x)

#define ALIGN_BIT1		0x1
#define ALIGN_BOUND1		ALIGN_BOUND2
#define ALIGN_ALIGN1(x)		ALIGN_ALIGN2(x)
#define ALIGN_TRUNC1(x)		ALIGN_TRUNC2(x)
#ifndef __amd64
#define ALIGN_CLRBIT1(x)	ALIGN_POINTER(ALIGN_INTEGER(x)&0xfffffffe)
#else /* __amd64 */
#define ALIGN_CLRBIT1(x)	ALIGN_POINTER(ALIGN_INTEGER(x)&0xfffffffffffffffe)
#endif /* __amd64 */
#define ALIGN_SETBIT1(x)	ALIGN_POINTER(ALIGN_INTEGER(x)|0x1)
#define ALIGN_TSTBIT1(x)	ALIGN_POINTER(ALIGN_INTEGER(x)&0x1)

#define ALIGN_BIT2		0x2
#ifndef __amd64
#define ALIGN_BOUND2		4
#define ALIGN_ALIGN2(x)		ALIGN_TRUNC2((x)+3)
#define ALIGN_TRUNC2(x)		ALIGN_POINTER(ALIGN_INTEGER(x)&0xfffffffc)
#define ALIGN_CLRBIT2(x)	ALIGN_POINTER(ALIGN_INTEGER(x)&0xfffffffd)
#else /* __amd64 */
#define ALIGN_BOUND2		16
#define ALIGN_ALIGN2(x)		ALIGN_TRUNC2((x)+15)
#define ALIGN_TRUNC2(x)		ALIGN_POINTER(ALIGN_INTEGER(x)&0xfffffffffffffff0)
#define ALIGN_CLRBIT2(x)	ALIGN_POINTER(ALIGN_INTEGER(x)&0xfffffffffffffffd)
#endif /* __amd64 */
#define ALIGN_SETBIT2(x)	ALIGN_POINTER(ALIGN_INTEGER(x)|0x2)
#define ALIGN_TSTBIT2(x)	ALIGN_POINTER(ALIGN_INTEGER(x)&0x2)

#endif

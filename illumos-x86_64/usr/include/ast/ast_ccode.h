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
/* : : generated from contrib/ast/src/lib/libast/features/ccode by iffe version 2012-07-17 : : */
#ifndef _def_ccode_ast
#define _def_ccode_ast	1
#define _sys_types	1	/* #include <sys/types.h> ok */

#define CC_ASCII	1		/* ISO-8859-1			*/
#define CC_EBCDIC_E	2		/* Xopen dd(1) EBCDIC		*/
#define CC_EBCDIC_I	3		/* Xopen dd(1) IBM		*/
#define CC_EBCDIC_O	4		/* IBM-1047 mvs OpenEdition	*/
#define CC_EBCDIC_S	5		/* Siemens posix-bc		*/
#define CC_EBCDIC_H	6		/* IBM-37 AS/400		*/
#define CC_EBCDIC_M	7		/* IBM mvs cobol		*/
#define CC_EBCDIC_U	8		/* microfocus cobol		*/

#define CC_MAPS		8		/* number of code maps		*/

#define CC_EBCDIC	CC_EBCDIC_E
#define CC_EBCDIC1	CC_EBCDIC_E
#define CC_EBCDIC2	CC_EBCDIC_I
#define CC_EBCDIC3	CC_EBCDIC_O

#define CC_NATIVE	CC_ASCII	/* native character code	*/
#define CC_ALIEN	CC_EBCDIC	/* alien character code		*/

#define CC_bel		0007		/* bel character		*/
#define CC_esc		0033		/* esc character		*/
#define CC_sub		0032		/* sub character		*/
#define CC_vt		0013		/* vt character			*/
#endif

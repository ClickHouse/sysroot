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
/* : : generated from contrib/ast/src/lib/libast/features/mode.c by iffe version 2012-07-17 : : */
#ifndef _def_mode_ast
#define _def_mode_ast	1
#define _sys_types	1	/* #include <sys/types.h> ok */
#define S_ITYPE(m)	((m)&S_IFMT)

#define S_IPERM		(S_ISUID|S_ISGID|S_ISVTX|S_IRWXU|S_IRWXG|S_IRWXO)

#define _S_IDPERM	1
#define _S_IDTYPE	1

#define BUFFERSIZE	8192

#endif

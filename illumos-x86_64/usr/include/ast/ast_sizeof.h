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
/* : : generated from contrib/ast/src/lib/libast/features/sizeof by iffe version 2012-07-17 : : */
#ifndef _def_sizeof_ast
#define _def_sizeof_ast	1
#define _sys_types	1	/* #include <sys/types.h> ok */
#define _ast_sizeof_char	1
#define _ast_sizeof_short	2
#define _ast_sizeof_int		4
#ifndef __amd64
#define _ast_sizeof_long	4
#else /* __amd64 */
#define _ast_sizeof_long	8
#endif /* __amd64 */
#define _ast_sizeof_intmax_t	8
#endif

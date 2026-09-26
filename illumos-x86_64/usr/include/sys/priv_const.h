/*
 * CDDL HEADER START
 *
 * The contents of this file are subject to the terms of the
 * Common Development and Distribution License (the "License").
 * You may not use this file except in compliance with the License.
 *
 * You can obtain a copy of the license at usr/src/OPENSOLARIS.LICENSE
 * or http://www.opensolaris.org/os/licensing.
 * See the License for the specific language governing permissions
 * and limitations under the License.
 *
 * When distributing Covered Code, include this CDDL HEADER in each
 * file and include the License file at usr/src/OPENSOLARIS.LICENSE.
 * If applicable, add the following below this CDDL HEADER, with the
 * fields enclosed by brackets "[]" replaced with your own identifying
 * information: Portions Copyright [yyyy] [name of copyright owner]
 *
 * CDDL HEADER END
 */
/*
 * Copyright (c) 2003, 2010, Oracle and/or its affiliates. All rights reserved.
 * Copyright 2015, Joyent, Inc. All rights reserved.
 *
 * Privilege constant definitions; these constants are subject to
 * change, including renumbering, without notice and should not be
 * used in any code.  Privilege names must be used instead.
 * Privileges and privilege sets must not be stored in binary
 * form; privileges and privileges sets must be converted to
 * textual representation before being committed to persistent store.
 *
 * THIS FILE WAS GENERATED; DO NOT EDIT
 */


#ifndef _SYS_PRIV_CONST_H
#define	_SYS_PRIV_CONST_H




#include <sys/types.h>


#ifdef __cplusplus
extern "C" {
#endif

#if defined(_KERNEL) || defined(_KMEMUSER)
#define	PRIV_NSET			  4
#define	PRIV_SETSIZE			  3
#endif

#ifdef _KERNEL
#define	__PRIV_CONST_IMPL

extern const char *priv_names[];
extern const char *priv_setnames[];
extern int nprivs;
extern int privbytes;
extern int maxprivbytes;
extern size_t privinfosize;
extern char *priv_str;
extern struct priv_set *priv_basic;
extern struct priv_impl_info *priv_info;
extern struct priv_info_names *priv_ninfo;

/* Privileges */
#define	PRIV_CONTRACT_EVENT	  0
#define	PRIV_CONTRACT_IDENTITY	  1
#define	PRIV_CONTRACT_OBSERVER	  2
#define	PRIV_CPC_CPU		  3
#define	PRIV_DTRACE_KERNEL	  4
#define	PRIV_DTRACE_PROC	  5
#define	PRIV_DTRACE_USER	  6
#define	PRIV_FILE_CHOWN		  7
#define	PRIV_FILE_CHOWN_SELF	  8
#define	PRIV_FILE_DAC_EXECUTE	  9
#define	PRIV_FILE_DAC_READ	 10
#define	PRIV_FILE_DAC_SEARCH	 11
#define	PRIV_FILE_DAC_WRITE	 12
#define	PRIV_FILE_DOWNGRADE_SL	 13
#define	PRIV_FILE_FLAG_SET	 14
#define	PRIV_FILE_LINK_ANY	 15
#define	PRIV_FILE_OWNER		 16
#define	PRIV_FILE_READ		 17
#define	PRIV_FILE_SETID		 18
#define	PRIV_FILE_UPGRADE_SL	 19
#define	PRIV_FILE_WRITE		 20
#define	PRIV_GRAPHICS_ACCESS	 21
#define	PRIV_GRAPHICS_MAP	 22
#define	PRIV_IPC_DAC_READ	 23
#define	PRIV_IPC_DAC_WRITE	 24
#define	PRIV_IPC_OWNER		 25
#define	PRIV_NET_ACCESS		 26
#define	PRIV_NET_BINDMLP	 27
#define	PRIV_NET_ICMPACCESS	 28
#define	PRIV_NET_MAC_AWARE	 29
#define	PRIV_NET_MAC_IMPLICIT	 30
#define	PRIV_NET_OBSERVABILITY	 31
#define	PRIV_NET_PRIVADDR	 32
#define	PRIV_NET_RAWACCESS	 33
#define	PRIV_PROC_AUDIT		 34
#define	PRIV_PROC_CHROOT	 35
#define	PRIV_PROC_CLOCK_HIGHRES	 36
#define	PRIV_PROC_EXEC		 37
#define	PRIV_PROC_FORK		 38
#define	PRIV_PROC_INFO		 39
#define	PRIV_PROC_LOCK_MEMORY	 40
#define	PRIV_PROC_MEMINFO	 41
#define	PRIV_PROC_OWNER		 42
#define	PRIV_PROC_PRIOUP	 43
#define	PRIV_PROC_PRIOCNTL	 44
#define	PRIV_PROC_SECFLAGS	 45
#define	PRIV_PROC_SESSION	 46
#define	PRIV_PROC_SETID		 47
#define	PRIV_PROC_TASKID	 48
#define	PRIV_PROC_ZONE		 49
#define	PRIV_SYS_ACCT		 50
#define	PRIV_SYS_ADMIN		 51
#define	PRIV_SYS_AUDIT		 52
#define	PRIV_SYS_CONFIG		 53
#define	PRIV_SYS_DEVICES	 54
#define	PRIV_SYS_IPC_CONFIG	 55
#define	PRIV_SYS_LINKDIR	 56
#define	PRIV_SYS_MOUNT		 57
#define	PRIV_SYS_IPTUN_CONFIG	 58
#define	PRIV_SYS_DL_CONFIG	 59
#define	PRIV_SYS_IP_CONFIG	 60
#define	PRIV_SYS_NET_CONFIG	 61
#define	PRIV_SYS_NFS		 62
#define	PRIV_SYS_PPP_CONFIG	 63
#define	PRIV_SYS_RES_BIND	 64
#define	PRIV_SYS_RES_CONFIG	 65
#define	PRIV_SYS_RESOURCE	 66
#define	PRIV_SYS_SMB		 67
#define	PRIV_SYS_SUSER_COMPAT	 68
#define	PRIV_SYS_TIME		 69
#define	PRIV_SYS_TRANS_LABEL	 70
#define	PRIV_VIRT_MANAGE	 71
#define	PRIV_WIN_COLORMAP	 72
#define	PRIV_WIN_CONFIG		 73
#define	PRIV_WIN_DAC_READ	 74
#define	PRIV_WIN_DAC_WRITE	 75
#define	PRIV_WIN_DEVICES	 76
#define	PRIV_WIN_DGA		 77
#define	PRIV_WIN_DOWNGRADE_SL	 78
#define	PRIV_WIN_FONTPATH	 79
#define	PRIV_WIN_MAC_READ	 80
#define	PRIV_WIN_MAC_WRITE	 81
#define	PRIV_WIN_SELECTION	 82
#define	PRIV_WIN_UPGRADE_SL	 83
#define	PRIV_XVM_CONTROL	 84

/* Privilege sets */
#define	PRIV_EFFECTIVE		  0
#define	PRIV_INHERITABLE	  1
#define	PRIV_PERMITTED		  2
#define	PRIV_LIMIT		  3

#define	MAX_PRIVILEGE			 96

#define	PRIV_UNSAFE_ASSERT(set)\
		PRIV_ASSERT((set), PRIV_PROC_AUDIT);\
		PRIV_ASSERT((set), PRIV_PROC_SETID);\
		PRIV_ASSERT((set), PRIV_SYS_RESOURCE)

#define	PRIV_BASIC_ASSERT(set)\
		PRIV_ASSERT((set), PRIV_FILE_LINK_ANY);\
		PRIV_ASSERT((set), PRIV_FILE_READ);\
		PRIV_ASSERT((set), PRIV_FILE_WRITE);\
		PRIV_ASSERT((set), PRIV_NET_ACCESS);\
		PRIV_ASSERT((set), PRIV_PROC_EXEC);\
		PRIV_ASSERT((set), PRIV_PROC_FORK);\
		PRIV_ASSERT((set), PRIV_PROC_INFO);\
		PRIV_ASSERT((set), PRIV_PROC_SECFLAGS);\
		PRIV_ASSERT((set), PRIV_PROC_SESSION)

#endif /* _KERNEL */

#ifdef __cplusplus
}
#endif

#endif /* _SYS_PRIV_CONST_H */

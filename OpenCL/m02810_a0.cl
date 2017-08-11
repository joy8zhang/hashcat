/**
 * Author......: See docs/credits.txt
 * License.....: MIT
 */

//#define NEW_SIMD_CODE

#include "inc_vendor.cl"
#include "inc_hash_constants.h"
#include "inc_hash_functions.cl"
#include "inc_types.cl"
#include "inc_common.cl"
#include "inc_rp_optimized.h"
#include "inc_rp_optimized.cl"
#include "inc_scalar.cl"
#include "inc_hash_md5.cl"

#if   VECT_SIZE == 1
#define uint_to_hex_lower8(i) (u32x) (l_bin2asc[(i)])
#elif VECT_SIZE == 2
#define uint_to_hex_lower8(i) (u32x) (l_bin2asc[(i).s0], l_bin2asc[(i).s1])
#elif VECT_SIZE == 4
#define uint_to_hex_lower8(i) (u32x) (l_bin2asc[(i).s0], l_bin2asc[(i).s1], l_bin2asc[(i).s2], l_bin2asc[(i).s3])
#elif VECT_SIZE == 8
#define uint_to_hex_lower8(i) (u32x) (l_bin2asc[(i).s0], l_bin2asc[(i).s1], l_bin2asc[(i).s2], l_bin2asc[(i).s3], l_bin2asc[(i).s4], l_bin2asc[(i).s5], l_bin2asc[(i).s6], l_bin2asc[(i).s7])
#elif VECT_SIZE == 16
#define uint_to_hex_lower8(i) (u32x) (l_bin2asc[(i).s0], l_bin2asc[(i).s1], l_bin2asc[(i).s2], l_bin2asc[(i).s3], l_bin2asc[(i).s4], l_bin2asc[(i).s5], l_bin2asc[(i).s6], l_bin2asc[(i).s7], l_bin2asc[(i).s8], l_bin2asc[(i).s9], l_bin2asc[(i).sa], l_bin2asc[(i).sb], l_bin2asc[(i).sc], l_bin2asc[(i).sd], l_bin2asc[(i).se], l_bin2asc[(i).sf])
#endif

__kernel void m02810_mxx (__global pw_t *pws, __global const kernel_rule_t *rules_buf, __global const pw_t *combs_buf, __global const bf_t *bfs_buf, __global void *tmps, __global void *hooks, __global const u32 *bitmaps_buf_s1_a, __global const u32 *bitmaps_buf_s1_b, __global const u32 *bitmaps_buf_s1_c, __global const u32 *bitmaps_buf_s1_d, __global const u32 *bitmaps_buf_s2_a, __global const u32 *bitmaps_buf_s2_b, __global const u32 *bitmaps_buf_s2_c, __global const u32 *bitmaps_buf_s2_d, __global plain_t *plains_buf, __global const digest_t *digests_buf, __global u32 *hashes_shown, __global const salt_t *salt_bufs, __global const void *esalt_bufs, __global u32 *d_return_buf, __global u32 *d_scryptV0_buf, __global u32 *d_scryptV1_buf, __global u32 *d_scryptV2_buf, __global u32 *d_scryptV3_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 il_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
  /**
   * modifier
   */

  const u32 gid = get_global_id (0);
  const u32 lid = get_local_id (0);
  const u32 lsz = get_local_size (0);

  /**
   * bin2asc table
   */

  __local u32 l_bin2asc[256];

  for (u32 i = lid; i < 256; i += lsz)
  {
    const u32 i0 = (i >> 0) & 15;
    const u32 i1 = (i >> 4) & 15;

    l_bin2asc[i] = ((i0 < 10) ? '0' + i0 : 'a' - 10 + i0) << 8
                 | ((i1 < 10) ? '0' + i1 : 'a' - 10 + i1) << 0;
  }

  barrier (CLK_LOCAL_MEM_FENCE);

  if (gid >= gid_max) return;

  /**
   * base
   */

  const u32 pw_len = pws[gid].pw_len;

  const u32 pw_lenv = ceil ((float) pw_len / 4);

  u32 w[64] = { 0 };

  for (int idx = 0; idx < pw_lenv; idx++)
  {
    w[idx] = pws[gid].i[idx];
  }

  const u32 salt_len = 32;

  const u32 salt_lenv = ceil ((float) salt_len / 4);

  u32 s[8] = { 0 };

  for (int idx = 0; idx < salt_lenv; idx++)
  {
    s[idx] = salt_bufs[salt_pos].salt_buf_pc[idx];
  }

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < il_cnt; il_pos++)
  {
    u32 out_buf[64] = { 0 };

    const u32 out_len = apply_rules (rules_buf[il_pos].cmds, w, pw_len, out_buf);

    md5_ctx_t ctx0;

    md5_init (&ctx0);

    md5_update (&ctx0, out_buf, out_len);

    md5_final (&ctx0);

    const u32 a = ctx0.h[0];
    const u32 b = ctx0.h[1];
    const u32 c = ctx0.h[2];
    const u32 d = ctx0.h[3];

    md5_ctx_t ctx;

    md5_init (&ctx);

    ctx.w0[0] = s[0];
    ctx.w0[1] = s[1];
    ctx.w0[2] = s[2];
    ctx.w0[3] = s[3];
    ctx.w1[0] = s[4];
    ctx.w1[1] = s[5];
    ctx.w1[2] = s[6];
    ctx.w1[3] = s[7];
    ctx.w2[0] = uint_to_hex_lower8 ((a >>  0) & 255) <<  0
              | uint_to_hex_lower8 ((a >>  8) & 255) << 16;
    ctx.w2[1] = uint_to_hex_lower8 ((a >> 16) & 255) <<  0
              | uint_to_hex_lower8 ((a >> 24) & 255) << 16;
    ctx.w2[2] = uint_to_hex_lower8 ((b >>  0) & 255) <<  0
              | uint_to_hex_lower8 ((b >>  8) & 255) << 16;
    ctx.w2[3] = uint_to_hex_lower8 ((b >> 16) & 255) <<  0
              | uint_to_hex_lower8 ((b >> 24) & 255) << 16;
    ctx.w3[0] = uint_to_hex_lower8 ((c >>  0) & 255) <<  0
              | uint_to_hex_lower8 ((c >>  8) & 255) << 16;
    ctx.w3[1] = uint_to_hex_lower8 ((c >> 16) & 255) <<  0
              | uint_to_hex_lower8 ((c >> 24) & 255) << 16;
    ctx.w3[2] = uint_to_hex_lower8 ((d >>  0) & 255) <<  0
              | uint_to_hex_lower8 ((d >>  8) & 255) << 16;
    ctx.w3[3] = uint_to_hex_lower8 ((d >> 16) & 255) <<  0
              | uint_to_hex_lower8 ((d >> 24) & 255) << 16;

    md5_transform (ctx.w0, ctx.w1, ctx.w2, ctx.w3, ctx.h);

    ctx.w0[0] = 0x80;
    ctx.w0[1] = 0;
    ctx.w0[2] = 0;
    ctx.w0[3] = 0;
    ctx.w1[0] = 0;
    ctx.w1[1] = 0;
    ctx.w1[2] = 0;
    ctx.w1[3] = 0;
    ctx.w2[0] = 0;
    ctx.w2[1] = 0;
    ctx.w2[2] = 0;
    ctx.w2[3] = 0;
    ctx.w3[0] = 0;
    ctx.w3[1] = 0;
    ctx.w3[2] = 64 * 8;
    ctx.w3[3] = 0;

    md5_transform (ctx.w0, ctx.w1, ctx.w2, ctx.w3, ctx.h);

    const u32 r0 = ctx.h[DGST_R0];
    const u32 r1 = ctx.h[DGST_R1];
    const u32 r2 = ctx.h[DGST_R2];
    const u32 r3 = ctx.h[DGST_R3];

    COMPARE_M_SCALAR (r0, r1, r2, r3);
  }
}

__kernel void m02810_sxx (__global pw_t *pws, __global const kernel_rule_t *rules_buf, __global const pw_t *combs_buf, __global const bf_t *bfs_buf, __global void *tmps, __global void *hooks, __global const u32 *bitmaps_buf_s1_a, __global const u32 *bitmaps_buf_s1_b, __global const u32 *bitmaps_buf_s1_c, __global const u32 *bitmaps_buf_s1_d, __global const u32 *bitmaps_buf_s2_a, __global const u32 *bitmaps_buf_s2_b, __global const u32 *bitmaps_buf_s2_c, __global const u32 *bitmaps_buf_s2_d, __global plain_t *plains_buf, __global const digest_t *digests_buf, __global u32 *hashes_shown, __global const salt_t *salt_bufs, __global const void *esalt_bufs, __global u32 *d_return_buf, __global u32 *d_scryptV0_buf, __global u32 *d_scryptV1_buf, __global u32 *d_scryptV2_buf, __global u32 *d_scryptV3_buf, const u32 bitmap_mask, const u32 bitmap_shift1, const u32 bitmap_shift2, const u32 salt_pos, const u32 loop_pos, const u32 loop_cnt, const u32 il_cnt, const u32 digests_cnt, const u32 digests_offset, const u32 combs_mode, const u32 gid_max)
{
  /**
   * modifier
   */

  const u32 gid = get_global_id (0);
  const u32 lid = get_local_id (0);
  const u32 lsz = get_local_size (0);

  /**
   * bin2asc table
   */

  __local u32 l_bin2asc[256];

  for (u32 i = lid; i < 256; i += lsz)
  {
    const u32 i0 = (i >> 0) & 15;
    const u32 i1 = (i >> 4) & 15;

    l_bin2asc[i] = ((i0 < 10) ? '0' + i0 : 'a' - 10 + i0) << 8
                 | ((i1 < 10) ? '0' + i1 : 'a' - 10 + i1) << 0;
  }

  barrier (CLK_LOCAL_MEM_FENCE);

  if (gid >= gid_max) return;

  /**
   * digest
   */

  const u32 search[4] =
  {
    digests_buf[digests_offset].digest_buf[DGST_R0],
    digests_buf[digests_offset].digest_buf[DGST_R1],
    digests_buf[digests_offset].digest_buf[DGST_R2],
    digests_buf[digests_offset].digest_buf[DGST_R3]
  };

  /**
   * base
   */

  const u32 pw_len = pws[gid].pw_len;

  const u32 pw_lenv = ceil ((float) pw_len / 4);

  u32 w[64] = { 0 };

  for (int idx = 0; idx < pw_lenv; idx++)
  {
    w[idx] = pws[gid].i[idx];
  }

  const u32 salt_len = 32;

  const u32 salt_lenv = ceil ((float) salt_len / 4);

  u32 s[8] = { 0 };

  for (int idx = 0; idx < salt_lenv; idx++)
  {
    s[idx] = salt_bufs[salt_pos].salt_buf_pc[idx];
  }

  /**
   * loop
   */

  for (u32 il_pos = 0; il_pos < il_cnt; il_pos++)
  {
    u32 out_buf[64] = { 0 };

    const u32 out_len = apply_rules (rules_buf[il_pos].cmds, w, pw_len, out_buf);

    md5_ctx_t ctx0;

    md5_init (&ctx0);

    md5_update (&ctx0, out_buf, out_len);

    md5_final (&ctx0);

    const u32 a = ctx0.h[0];
    const u32 b = ctx0.h[1];
    const u32 c = ctx0.h[2];
    const u32 d = ctx0.h[3];

    md5_ctx_t ctx;

    md5_init (&ctx);

    ctx.w0[0] = s[0];
    ctx.w0[1] = s[1];
    ctx.w0[2] = s[2];
    ctx.w0[3] = s[3];
    ctx.w1[0] = s[4];
    ctx.w1[1] = s[5];
    ctx.w1[2] = s[6];
    ctx.w1[3] = s[7];
    ctx.w2[0] = uint_to_hex_lower8 ((a >>  0) & 255) <<  0
              | uint_to_hex_lower8 ((a >>  8) & 255) << 16;
    ctx.w2[1] = uint_to_hex_lower8 ((a >> 16) & 255) <<  0
              | uint_to_hex_lower8 ((a >> 24) & 255) << 16;
    ctx.w2[2] = uint_to_hex_lower8 ((b >>  0) & 255) <<  0
              | uint_to_hex_lower8 ((b >>  8) & 255) << 16;
    ctx.w2[3] = uint_to_hex_lower8 ((b >> 16) & 255) <<  0
              | uint_to_hex_lower8 ((b >> 24) & 255) << 16;
    ctx.w3[0] = uint_to_hex_lower8 ((c >>  0) & 255) <<  0
              | uint_to_hex_lower8 ((c >>  8) & 255) << 16;
    ctx.w3[1] = uint_to_hex_lower8 ((c >> 16) & 255) <<  0
              | uint_to_hex_lower8 ((c >> 24) & 255) << 16;
    ctx.w3[2] = uint_to_hex_lower8 ((d >>  0) & 255) <<  0
              | uint_to_hex_lower8 ((d >>  8) & 255) << 16;
    ctx.w3[3] = uint_to_hex_lower8 ((d >> 16) & 255) <<  0
              | uint_to_hex_lower8 ((d >> 24) & 255) << 16;

    md5_transform (ctx.w0, ctx.w1, ctx.w2, ctx.w3, ctx.h);

    ctx.w0[0] = 0x80;
    ctx.w0[1] = 0;
    ctx.w0[2] = 0;
    ctx.w0[3] = 0;
    ctx.w1[0] = 0;
    ctx.w1[1] = 0;
    ctx.w1[2] = 0;
    ctx.w1[3] = 0;
    ctx.w2[0] = 0;
    ctx.w2[1] = 0;
    ctx.w2[2] = 0;
    ctx.w2[3] = 0;
    ctx.w3[0] = 0;
    ctx.w3[1] = 0;
    ctx.w3[2] = 64 * 8;
    ctx.w3[3] = 0;

    md5_transform (ctx.w0, ctx.w1, ctx.w2, ctx.w3, ctx.h);

    const u32 r0 = ctx.h[DGST_R0];
    const u32 r1 = ctx.h[DGST_R1];
    const u32 r2 = ctx.h[DGST_R2];
    const u32 r3 = ctx.h[DGST_R3];

    COMPARE_S_SCALAR (r0, r1, r2, r3);
  }
}

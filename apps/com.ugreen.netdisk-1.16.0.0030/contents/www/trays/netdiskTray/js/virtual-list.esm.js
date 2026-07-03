(function () {
  'use strict';
  try {
    if (typeof document < 'u') {
      var t = document.createElement('style');
      t.appendChild(
        document.createTextNode(
          '.virtual-list-wrapper[data-v-3ce39090]{position:relative;width:100%;height:100%;overflow:hidden}.visible-container[data-v-3ce39090]{position:absolute;top:0;left:0;width:100%;z-index:1;overflow:hidden;overscroll-behavior:contain;pointer-events:none}.list-item[data-v-3ce39090]{width:100%;position:relative;pointer-events:auto}.virtual-scroll-container[data-v-3ce39090]{position:relative;width:100%;height:100%;overflow-x:hidden;overflow-y:auto;-webkit-overflow-scrolling:touch;z-index:2}.scroll-content[data-v-3ce39090]{width:100%;position:relative}.scroll-skeleton[data-v-3ce39090]{position:absolute;top:0;left:0;z-index:3;pointer-events:auto;background:transparent;opacity:0!important;filter:alpha(opacity=0)!important}.skeleton-item[data-v-3ce39090]{width:100%;background:transparent;position:relative;z-index:3}.virtual-list-container[data-v-d07470e2]{width:100%;position:relative;overflow-x:hidden;overflow-y:auto;-webkit-overflow-scrolling:touch}.roll-container[data-v-d07470e2]{position:relative;transition:transform .3s ease-in-out}.visible-container[data-v-d07470e2]{position:absolute;top:0;width:100%;will-change:transform;backface-visibility:hidden;transform:translateZ(0)}.list-item[data-v-d07470e2]{text-align:center;position:relative}.list-item[data-v-d07470e2]:hover{background-color:#0000000f}'
        )
      ),
        document.head.appendChild(t);
    }
  } catch (e) {
    console.error('vite-plugin-css-injected-by-js', e);
  }
})();
import {
  defineComponent as N,
  ref as s,
  computed as r,
  watch as q,
  nextTick as Z,
  onMounted as G,
  onBeforeUnmount as J,
  createElementBlock as b,
  openBlock as g,
  normalizeStyle as p,
  createElementVNode as _,
  Fragment as z,
  renderList as A,
  renderSlot as Y,
  createBlock as ee,
  resolveDynamicComponent as te,
  mergeProps as le,
  withCtx as oe,
  normalizeProps as ae,
  guardReactiveProps as se,
} from 'vue';
const ne = /* @__PURE__ */ N({
    name: 'skeletonList',
    __name: 'skeletonList',
    props: {
      listData: { default: () => [] },
      itemHeight: { default: 50 },
      itemWidth: { default: 0 },
      height: { default: 500 },
      scrollEndDistance: { default: 10 },
      scrollLockTime: { default: 0 },
      tableStyle: { default: () => ({}) },
      rowStyle: { default: () => ({}) },
      scrollbarWidth: { default: 6 },
    },
    emits: ['scrollToBottom', 'scroll'],
    setup(T, { expose: x, emit: S }) {
      const e = T,
        f = S,
        h = s(0),
        n = s(null),
        o = s(!1),
        u = s(0),
        k = s(0),
        M = s(!1),
        m = s(null),
        y = s(null),
        v = s(),
        D = r(() => e.listData.length * e.itemHeight),
        E = r(() => Math.min(e.listData.length, Math.ceil(e.height / e.itemHeight))),
        w = r(() => h.value % e.itemHeight),
        d = r(() => Math.max(0, D.value - e.height)),
        B = r(() => e.listData.slice(u.value, k.value)),
        V = r(() => M.value),
        P = () => {
          n.value && (clearTimeout(n.value), (n.value = null));
        },
        L = () => {
          v.value && (M.value = v.value.scrollHeight > v.value.clientHeight);
        },
        H = (t = h.value) => {
          if (!e.listData.length) {
            (h.value = 0), (u.value = 0), (k.value = 0);
            return;
          }
          const l = E.value;
          (h.value = t),
            (u.value = Math.max(0, Math.floor(t / e.itemHeight))),
            (k.value = Math.min(e.listData.length, u.value + l + 1));
        },
        I = (t = 0) => {
          const l = Math.min(d.value, Math.max(0, t || 0));
          v.value && v.value.scrollTop !== l && (v.value.scrollTop = l), H(l);
        },
        O = t => {
          const i = t.target.scrollTop;
          if (o.value || i === h.value) return;
          i + e.scrollEndDistance >= d.value && (f('scrollToBottom'), e.scrollLockTime > 0 && $()),
            (h.value = i),
            H(i),
            f('scroll');
        },
        R = t => {
          const l = v.value;
          if (!l || d.value <= 0) return;
          const i = Math.min(d.value, Math.max(0, l.scrollTop + t.deltaY));
          i !== l.scrollTop && ((l.scrollTop = i), t.preventDefault());
        },
        a = t => {
          var i, c;
          const l = v.value;
          l &&
            (i = t.touches) != null &&
            i.length &&
            ((m.value = ((c = t.touches[0]) == null ? void 0 : c.clientY) ?? null), (y.value = l.scrollTop));
        },
        W = t => {
          var U, j;
          const l = v.value;
          if (!l || d.value <= 0 || !((U = t.touches) != null && U.length) || m.value == null || y.value == null) return;
          const c = (((j = t.touches[0]) == null ? void 0 : j.clientY) ?? m.value) - m.value,
            K = Math.min(d.value, Math.max(0, y.value - c));
          K !== l.scrollTop && ((l.scrollTop = K), t.preventDefault());
        },
        C = () => {
          (m.value = null), (y.value = null);
        },
        $ = () => {
          n.value && (clearTimeout(n.value), (n.value = null)),
            (o.value = !0),
            (n.value = setTimeout(() => {
              (o.value = !1), (n.value = null);
            }, e.scrollLockTime));
        };
      q(
        () => e.listData.length,
        () => {
          Z(() => {
            I(h.value), L();
          });
        }
      ),
        q(
          () => e.height,
          () => {
            I(h.value), L();
          }
        );
      const F = r(() => (e.itemWidth ? `${e.itemWidth}px` : V.value ? `calc(100% - ${e.scrollbarWidth}px)` : '100%')),
        X = t => {
          t == null || t < 0 || t === void 0 || I(t * e.itemHeight);
        };
      return (
        G(() => {
          H(), L();
        }),
        J(() => {
          P();
        }),
        x({
          scrollTo: X,
        }),
        (t, l) => (
          g(),
          b(
            'div',
            {
              class: 'virtual-list-wrapper skeleton-list',
              style: p({ height: `${t.height}px` }),
            },
            [
              _(
                'div',
                {
                  class: 'visible-container',
                  style: p({
                    transform: `translateY(-${w.value}px)`,
                    ...t.tableStyle,
                  }),
                },
                [
                  (g(!0),
                  b(
                    z,
                    null,
                    A(
                      B.value,
                      (i, c) => (
                        g(),
                        b(
                          'div',
                          {
                            key: `list-item-${c}`,
                            class: 'list-item',
                            style: p({
                              height: `${t.itemHeight}px`,
                              width: F.value,
                              ...t.rowStyle,
                            }),
                          },
                          [
                            Y(
                              t.$slots,
                              'default',
                              {
                                item: i,
                                index: u.value + c,
                                reuseDom: !0,
                                visibleIndex: c,
                              },
                              void 0,
                              !0
                            ),
                          ],
                          4
                        )
                      )
                    ),
                    128
                  )),
                ],
                4
              ),
              _(
                'div',
                {
                  class: 'virtual-scroll-container',
                  ref_key: 'scrollContainer',
                  ref: v,
                  onScrollPassive: O,
                },
                [
                  _(
                    'div',
                    {
                      class: 'scroll-content',
                      style: p({ height: `${D.value}px` }),
                    },
                    null,
                    4
                  ),
                ],
                544
              ),
              _(
                'div',
                {
                  class: 'scroll-skeleton',
                  style: p({
                    width: F.value,
                    top: '0px',
                    left: '0px',
                    transform: `translateY(-${w.value}px)`,
                    ...t.tableStyle,
                  }),
                  onWheel: R,
                  onTouchstart: a,
                  onTouchmove: W,
                  onTouchend: C,
                  onTouchcancel: C,
                },
                [
                  (g(!0),
                  b(
                    z,
                    null,
                    A(
                      B.value,
                      (i, c) => (
                        g(),
                        b(
                          'div',
                          {
                            key: `skeleton-item-${c}`,
                            class: 'skeleton-item',
                            style: p({ height: `${t.itemHeight}px`, width: '100%', ...t.rowStyle }),
                          },
                          [
                            Y(
                              t.$slots,
                              'default',
                              {
                                item: i,
                                index: u.value + c,
                                reuseDom: !0,
                                visibleIndex: c,
                              },
                              void 0,
                              !0
                            ),
                          ],
                          4
                        )
                      )
                    ),
                    128
                  )),
                ],
                36
              ),
            ],
            4
          )
        )
      );
    },
  }),
  Q = (T, x) => {
    const S = T.__vccOpts || T;
    for (const [e, f] of x) S[e] = f;
    return S;
  },
  re = /* @__PURE__ */ Q(ne, [['__scopeId', 'data-v-3ce39090']]),
  ue = /* @__PURE__ */ N({
    name: 'navVirtualList',
    __name: 'virtualList',
    props: {
      listData: { default: () => [] },
      itemHeight: { default: 50 },
      itemWidth: { default: 0 },
      itemKey: { default: 'id' },
      height: { default: 500 },
      bufferScale: { default: 2 },
      scrollEndIndex: { default: 0 },
      scrollLockTime: { default: 100 },
    },
    emits: ['scrollToBottom', 'scroll'],
    setup(T, { expose: x, emit: S }) {
      const e = T,
        f = S,
        h = s(0),
        n = s(0),
        o = s(null),
        u = s(!1),
        k = s(0),
        M = s(0),
        m = s(null),
        y = s(null),
        v = r(() => e.listData.length * e.itemHeight),
        D = r(() => Math.ceil(e.height / e.itemHeight)),
        E = r(() => Math.min(k.value, e.bufferScale * D.value)),
        w = r(() => Math.min(e.listData.length - M.value, e.bufferScale * D.value)),
        d = r(() => k.value - E.value),
        B = r(() => M.value + w.value),
        V = r(() => e.listData.slice(d.value, B.value)),
        P = r(() => B.value >= e.listData.length - e.scrollEndIndex),
        L = (a = 0) => {
          y.value && (y.value.style.transform = `translate3d(0,${a}px,0)`);
        },
        H = (a = 0) => {
          (k.value = Math.floor(a / e.itemHeight)),
            (M.value = k.value + D.value),
            L(d.value * e.itemHeight),
            P.value && (f('scrollToBottom'), O());
        },
        I = a => {
          const W = a.target;
          if (((n.value = W.scrollTop), u.value)) return;
          const C = Math.max(0, e.listData.length * e.itemHeight - e.height),
            $ = Math.min(C, Math.max(0, n.value));
          (h.value = $), H($), f('scroll');
        },
        O = () => {
          o.value && (clearTimeout(o.value), (o.value = null)),
            (u.value = !0),
            (o.value = setTimeout(() => {
              (u.value = !1), (o.value = null);
            }, e.scrollLockTime));
        },
        R = a => {
          a == null || a < 0 || a === void 0 || (m.value && (m.value.scrollTop = a * e.itemHeight));
        };
      return (
        G(() => {
          m.value && (m.value.scrollTop = 0), H();
        }),
        J(() => {
          o.value && (clearTimeout(o.value), (o.value = null));
        }),
        x({
          scrollTo: R,
        }),
        (a, W) => (
          g(),
          b(
            'section',
            {
              class: 'virtual-list-container',
              ref_key: 'scrollContainer',
              ref: m,
              onScrollPassive: I,
              style: p({ height: `${a.height}px` }),
            },
            [
              _(
                'div',
                {
                  class: 'roll-container',
                  style: p({ height: `${v.value}px` }),
                },
                null,
                4
              ),
              _(
                'div',
                {
                  class: 'visible-container',
                  ref_key: 'content',
                  ref: y,
                },
                [
                  (g(!0),
                  b(
                    z,
                    null,
                    A(
                      V.value,
                      (C, $) => (
                        g(),
                        b(
                          'div',
                          {
                            key: $,
                            class: 'list-item',
                            style: p({
                              height: `${a.itemHeight}px`,
                              width: a.itemWidth ? `${a.itemWidth}px` : '100%',
                            }),
                          },
                          [
                            Y(
                              a.$slots,
                              'default',
                              {
                                item: C,
                                index: $,
                              },
                              void 0,
                              !0
                            ),
                          ],
                          4
                        )
                      )
                    ),
                    128
                  )),
                ],
                512
              ),
            ],
            36
          )
        )
      );
    },
  }),
  ie = /* @__PURE__ */ Q(ue, [['__scopeId', 'data-v-d07470e2']]),
  ve = /* @__PURE__ */ N({
    name: 'VirtualList',
    __name: 'index',
    props: {
      enableSkeleton: { type: Boolean },
    },
    setup(T, { expose: x }) {
      const S = T,
        e = r(() => (S.enableSkeleton ? re : ie)),
        f = s(null);
      return (
        x({
          scrollTo: n => {
            var o, u;
            (u = (o = f.value) == null ? void 0 : o.scrollTo) == null || u.call(o, n);
          },
        }),
        (n, o) => (
          g(),
          ee(
            te(e.value),
            le(
              {
                ref_key: 'innerRef',
                ref: f,
              },
              n.$attrs
            ),
            {
              default: oe(u => [Y(n.$slots, 'default', ae(se(u)))]),
              _: 3,
            },
            16
          )
        )
      );
    },
  });
export { ve as default };

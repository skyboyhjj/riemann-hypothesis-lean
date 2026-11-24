import Main

-- 公理依赖审计：五个终定理逐个 #print axioms
-- 判据（见规划任务清单阶段 2.1）：
--   每个定理只依赖 propext / Classical.choice / Quot.sound（含宇宙变体）
-- 运行方式：编译完成后，在项目根目录执行
--   source /etc/profile.d/lean.sh && lake env lean verification/04-scripts/Audit.lean

#print axioms riemannHypothesis
#print axioms riemannZeta_eq_zero_re
#print axioms LFunction_ne_zero_of_half_lt_re
#print axioms LFunction_eq_zero_re
#print axioms LFunction_eq_zero_re_of_isPrimitive

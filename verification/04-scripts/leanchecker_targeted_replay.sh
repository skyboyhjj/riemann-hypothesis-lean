#!/usr/bin/env bash
# leanchecker 定向内核重放（阶段 3.5）
# 目标：对 30 个含自定义 macro/elab/syntax 的模块 + 唯一 addDecl 模块（CutCptCopy），
#       用 Lean 4 内置 leanchecker 重放 .olean，排除 elaborator/metaprogram 构造不一致 Environment 的可能。
#
# 用法（远程主编译机，.olean 树已就绪）：
#   export PATH=/opt/lean-4.33.1/bin:$PATH
#   cd /data/riemann-hypothesis-lean-2026-11-20
#   # 分离运行，避免 SSH 断开连带杀掉：
#   nohup bash leanchecker_targeted_replay.sh > leanchecker_replay.out 2>&1 &
#
# 依赖：leanchecker（Lean 4.33.1 内置）；必须用 `lake env` 设置 LEAN_PATH。
set -u
export PATH=/opt/lean-4.33.1/bin:$PATH
REPO=/data/riemann-hypothesis-lean-2026-11-20
RESULTS="${RESULTS:-/data/lc_targeted/results.log}"

MODULES=(
Formalism.EllipticTorsion.EllipticTorsionProofs.Change
Formalism.LocalToGlobal.TorsionIntegrality.TorsionTranslationPowers.NonsingularJetNorms.NonsingularNorm
Formalism.LocalToGlobal.IndefiniteReal.HeckeNonvanishing.Imports
ReciprocityTheory.ReductiveGroups.ArithmeticGeometry.ExtensionDescent.Theta1
Formalism.LocalToGlobal.IndefiniteForms.IndefiniteTree.FunctionalLowerBoundOfConditionsNumeric
ReciprocityTheory.ReductiveGroups.ArithmeticGeometry.DiscreteValuationRings.ExistsRosatiGen
Formalism.HermitianCurvature.HermitianCurvatureProofs.RttUpperRelationsFromDescent
Formalism.HermitianCurvature.HermitianCurvatureProofs.CutCptCopy
Formalism.SharpRestriction.Divisibility.LocalNonemptiness.SubsingletonRankIndicatorIff
Formalism.LocalToGlobal.NumberFieldFamilies.OwnStruct
Development.WeilBound.CoreStatements.HodgeTatePoints.CcBase
Development.WeilBound.CoreStatements.HodgeTatePoints.CbBase
Formalism.SatakeDualWeyl.AdelicIwasawaHecke.FIwasawaC
Development.WeilBound.CoreStatements.PadicHodgeComparison.EtaleCohomologyComparison.CechPairings.FaceMapCompSuccAboveCastSucc
Formalism.PeriodIntegrals.UnitaryGroupMassFormula.GaussianUniqueness.MulMApply
Formalism.PeriodIntegrals.UnitaryGroupMassFormula.DensityLemma.PFibreBoundV
Development.EtaleCohomology.EtaleSheaves.ChasePf
Development.AutomorphicSpectrum.Proofs.BlockDecomposition.Cup1CoboundaryMemBoundaries
Development.AutomorphicSpectrum.Proofs.BlockDecomposition.ShuffleCup1FormulaPositiveDegree
Development.AbelianVarietyTheory.Definitions.GaloisGeometry.NegOnePowBoundaryTermsCancel
Development.AbelianVarietyTheory.Definitions.AutomorphicMembership.RealIoX
Development.AbelianVarietyTheory.Definitions.AutomorphicMembership.PlaceModelImp
Development.AbelianVarietyTheory.Definitions.AutomorphicMembership.GoodPartEq
Development.AbelianVarietyTheory.Proofs.DivisorProofs.ExistsMeasY
Development.AbelianVarietyTheory.Proofs.IwasawaDecomposition.RealDatumPrerequisitesUpdateModels
Development.AbelianVarietyTheory.Proofs.IwasawaDecomposition.RingSpecNormalisedCharacterEq
Development.AbelianVarietyTheory.Proofs.IwasawaDecomposition.RigidFrameSymmetricRatioSeries
Development.AbelianVarietyTheory.Proofs.InertiaEigenvalues.IsClassSystem
Development.AbelianVarietyTheory.Proofs.InertiaEigenvalues.SetupRelIffSameData
Development.AbelianVarietyTheory.Proofs.DivisorProofs.IsProperOfFiniteType
)

cd "$REPO" || { echo "REPO_MISSING" >> "$RESULTS"; exit 1; }

TOTAL=${#MODULES[@]}
OK=0
FAIL=0
for m in "${MODULES[@]}"; do
  olean="$REPO/.lake/build/lib/lean/${m//./\/}.olean"
  if [ ! -f "$olean" ]; then
    echo "MISSING_OLEAN $m" >> "$RESULTS"
    FAIL=$((FAIL+1))
    continue
  fi
  out=$(timeout 600 lake env leanchecker "$m" 2>&1)
  rc=$?
  if [ $rc -eq 0 ]; then
    echo "OK $m" >> "$RESULTS"
    OK=$((OK+1))
  else
    echo "FAIL $m rc=$rc :: $(echo "$out" | tail -5 | tr '\n' ' ')" >> "$RESULTS"
    FAIL=$((FAIL+1))
  fi
done

echo "TOTAL=$TOTAL OK=$OK FAIL=$FAIL" >> "$RESULTS"

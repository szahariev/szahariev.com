#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
  printf 'Usage: %s assets/diagrams/<diagram>.svg\n' "$0" >&2
  exit 1
fi

diagram=$1
case "$(basename -- "$diagram")" in
  sovereignty-control-path.svg)
    diagram_id=control-path
    diagram_title='The complete cloud control path'
    diagram_description='A request passes through identity, authorization and the cloud API before reaching infrastructure and data. Software supply, audit evidence and key authority are additional parts of the control path. Only the infrastructure and data sit inside the data-location boundary.'
    ;;
  sovereignty-five-tests.svg)
    diagram_id=five-tests
    diagram_title='Five sovereignty claims and their tests'
    diagram_description='Operator control depends on five claims: authority is tested by revocation, key custody by withholding access, evidence by independent verification, continuity by disconnection and exit by rehearsal.'
    ;;
  sovereignty-control-path-bg.svg)
    diagram_id=control-path-bg
    diagram_title='Пълният път на управление в облака'
    diagram_description='Заявката преминава през идентичност, авторизация и облачния API, преди да достигне инфраструктурата и данните. Доставката на софтуер, одитните доказателства и контролът върху ключовете също са част от пътя. Само инфраструктурата и данните са в границата на посоченото местоположение.'
    ;;
  sovereignty-five-tests-bg.svg)
    diagram_id=five-tests-bg
    diagram_title='Пет твърдения за суверенност и техните проверки'
    diagram_description='Контролът на оператора зависи от пет твърдения: правомощията се проверяват чрез отмяна, ключовете чрез спиране на достъпа, доказателствата чрез независима проверка, непрекъснатостта чрез изключване, а изходът чрез репетиция.'
    ;;
  *)
    printf 'No accessibility metadata is defined for %s.\n' "$diagram" >&2
    exit 1
    ;;
esac

if [ ! -f "$diagram" ]; then
  printf 'Diagram not found: %s\n' "$diagram" >&2
  exit 1
fi

if rg -q 'aria-labelledby=' "$diagram"; then
  printf 'Diagram already appears to be prepared: %s\n' "$diagram" >&2
  exit 1
fi

DIAGRAM_ID=$diagram_id \
DIAGRAM_TITLE=$diagram_title \
DIAGRAM_DESCRIPTION=$diagram_description \
perl -0pi -e '
  BEGIN {
    $id = $ENV{"DIAGRAM_ID"};
    $title = $ENV{"DIAGRAM_TITLE"};
    $description = $ENV{"DIAGRAM_DESCRIPTION"};
  }
  s{\A<\?xml[^>]*>\s*}{}s;
  s{\A<!DOCTYPE[^>]*>\s*}{}s;
  s{(<svg\b[^>]*>)}{$1\n  <title id="$id-title">$title</title>\n  <desc id="$id-desc">$description</desc>}s or die "SVG root not found\n";
  s{<svg\b}{<svg role="img" aria-labelledby="$id-title $id-desc"}s;
  s{#141927}{var(--obsidian, #141927)}gi;
  s{#2C3A52}{var(--steel, #2c3a52)}gi;
  s{#172B47}{var(--body-glow, #172b47)}gi;
  s{#4F8FDC}{var(--accent, #4f8fdc)}gi;
  s{#71B0F5}{var(--accent-strong, #71b0f5)}gi;
  s{#8896A8}{var(--mist, #8896a8)}gi;
  s{#EEF1F5}{var(--frost, #eef1f5)}gi;
  s{#A8D2FF}{var(--accent-soft, #a8d2ff)}gi;
  s{rgb\(\s*20\s*,\s*25\s*,\s*39\s*\)}{var(--obsidian, #141927)}gi;
  s{rgb\(\s*44\s*,\s*58\s*,\s*82\s*\)}{var(--steel, #2c3a52)}gi;
  s{rgb\(\s*23\s*,\s*43\s*,\s*71\s*\)}{var(--body-glow, #172b47)}gi;
  s{rgb\(\s*79\s*,\s*143\s*,\s*220\s*\)}{var(--accent, #4f8fdc)}gi;
  s{rgb\(\s*113\s*,\s*176\s*,\s*245\s*\)}{var(--accent-strong, #71b0f5)}gi;
  s{rgb\(\s*136\s*,\s*150\s*,\s*168\s*\)}{var(--mist, #8896a8)}gi;
  s{rgb\(\s*238\s*,\s*241\s*,\s*245\s*\)}{var(--frost, #eef1f5)}gi;
  s{rgb\(\s*168\s*,\s*210\s*,\s*255\s*\)}{var(--accent-soft, #a8d2ff)}gi;
' "$diagram"

printf 'Prepared %s for inline use.\n' "$diagram"

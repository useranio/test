package visualizer;

import js.html.Text;
import js.html.SpanElement;
import js.html.DivElement;
import js.JQuery;
import js.html.TableRowElement;
import js.html.TableCellElement;
import js.html.TableRowElement;
import js.html.TableElement;
import js.Browser;


enum Orientation {
    Vertical;
    Horizontal;
}


class MatchupChart {
    static var NUM_POKEMON_PER_TEAM = 3;
    static var NUM_MOVES_PER_POKEMON = 4;
    static var POKEMON_LABEL = 1;
    static var POKEMON_MOVES_LABEL = 1;
    static var DIVIDER = 1;

    var pokemonDataset:PokemonDataset;
    var movesDataset:MovesDataset;
    var descriptionsDataset:DescriptionsDataset;
    var pokemonStats:Array<Dynamic>;
    var tableElement:TableElement;

    public function new(pokemonDataset:PokemonDataset, movesDataset:MovesDataset, descriptionsDataset:DescriptionsDataset) {
        this.pokemonDataset = pokemonDataset;
        this.movesDataset = movesDataset;
        this.descriptionsDataset = descriptionsDataset;
    }

    public function setPokemon(pokemonStats:Array<Dynamic>) {
        this.pokemonStats = pokemonStats;
    }

    public function renderTable():TableElement {
        tableElement = Browser.document.createTableElement();
        tableElement.classList.add("matchupChart");

        var maxWidth = POKEMON_LABEL + POKEMON_MOVES_LABEL + NUM_POKEMON_PER_TEAM * NUM_MOVES_PER_POKEMON;

        renderTopPokemonLabelRow(cast(tableElement.insertRow(-1), TableRowElement));
        renderTopPokemonMovesRow(cast(tableElement.insertRow(-1), TableRowElement));

        for (moveRowIndex in 0...NUM_POKEMON_PER_TEAM * (NUM_MOVES_PER_POKEMON + DIVIDER)) {
            renderMoveRow(moveRowIndex, cast(tableElement.insertRow(-1), TableRowElement));
        }

        return tableElement;
    }

    function renderTopPokemonLabelRow(rowElement:TableRowElement) {
        var cornerCell = cast(rowElement.insertCell(-1), TableCellElement);
        cornerCell.colSpan = cornerCell.rowSpan = POKEMON_LABEL + POKEMON_MOVES_LABEL;

        for (slotNum in [3, 4, 5]) {
            var pokemonStat = pokemonStats[slotNum];
            var labelCell = cast(rowElement.insertCell(-1), TableCellElement);
            labelCell.colSpan = DIVIDER + NUM_MOVES_PER_POKEMON;
            processPokemonLabelCell(pokemonStat, labelCell, "top");
        }
    }

    function renderTopPokemonMovesRow(rowElement:TableRowElement) {
        for (slotNum in [3, 4, 5]) {
            var pokemonStat = pokemonStats[slotNum];

            renderDividerCell(rowElement);

            for (moveIndex in 0...NUM_MOVES_PER_POKEMON) {
                renderMoveLabelCell(pokemonStat, moveIndex, rowElement, "top");
            }
        }
    }

    function renderMoveRow(rowIndex:Int, rowElement:TableRowElement) {
        var cellLength = DIVIDER + NUM_MOVES_PER_POKEMON;
        var leftSlotNum = Std.int(rowIndex / cellLength);
        var leftMoveIndex = Std.int(rowIndex % cellLength) - 1;
        var leftPokemonStat = pokemonStats[leftSlotNum];

        if (rowIndex % cellLength == 0) {
            renderLeftPokemonLabel(leftPokemonStat, rowElement);

            renderDividerCell(rowElement);
        }

        if (leftMoveIndex >= 0) {
            renderMoveLabelCell(leftPokemonStat, leftMoveIndex, rowElement, "left");
        }

        for (topSlotNum in 3...6) {
            var topPokemonStat = pokemonStats[topSlotNum];
            renderVersusMatrix(rowElement, leftMoveIndex, leftPokemonStat, topPokemonStat);
        }

    }

    function renderVersusMatrix(rowElement:TableRowElement, leftMoveIndex:Int, leftPokemonStat:Dynamic, topPokemonStat:Dynamic) {
        if (leftMoveIndex == -1) {
            var dividerCell = renderDividerCell(rowElement, "first");
            var dividerCellWhoFaster;

            if (leftPokemonStat.speed > topPokemonStat.speed) {
                dividerCellWhoFaster = "blue";
            } else if (leftPokemonStat.speed < topPokemonStat.speed) {
                dividerCellWhoFaster = "red";
            } else {
                dividerCellWhoFaster = "tie";
            }
            dividerCell.classList.add('matchupChartDividerCellSpeed-$dividerCellWhoFaster');

            var topPokemonMoveSlugs:Array<String> = topPokemonStat.moves;

            for (topMoveIndex in 0...NUM_MOVES_PER_POKEMON) {
                var cell = cast(rowElement.insertCell(-1), TableCellElement);
                cell.rowSpan = topMoveIndex + 1;

                if (topMoveIndex < topPokemonMoveSlugs.length) {
                    var moveStat = movesDataset.getMoveStats(topPokemonMoveSlugs[topMoveIndex]);

                    processCellEfficacy(cell, moveStat, topPokemonStat, leftPokemonStat);
                }
            }
        } else {
            var cell = cast(rowElement.insertCell(-1), TableCellElement);
            cell.colSpan = leftMoveIndex + 1;

            var leftPokemonMoveSlugs:Array<String> = leftPokemonStat.moves;

            if (leftMoveIndex < leftPokemonMoveSlugs.length) {
                var moveStat = movesDataset.getMoveStats(leftPokemonMoveSlugs[leftMoveIndex]);

                processCellEfficacy(cell, moveStat, leftPokemonStat, topPokemonStat);
            }

            renderDividerCell(rowElement);
        }
    }

    function renderLeftPokemonLabel(pokemonStat:Dynamic, rowElement:TableRowElement) {
        var labelCell = cast(rowElement.insertCell(-1), TableCellElement);
        labelCell.rowSpan = DIVIDER + NUM_MOVES_PER_POKEMON;
        processPokemonLabelCell(pokemonStat, labelCell, "left");
    }

    function renderMoveLabelCell(pokemonStat:Dynamic, moveIndex:Int, rowElement:TableRowElement, position:String) {
        var labelCell = cast(rowElement.insertCell(-1), TableCellElement);
        var moveSlugs:Array<String> = pokemonStat.moves;

        if (moveIndex < moveSlugs.length) {
            var moveSlug = moveSlugs[moveIndex];
            var moveStats = movesDataset.getMoveStats(moveSlug);

            processMoveLabelCell(moveStats, labelCell, position);
        }
    }

    function processPokemonLabelCell(pokemonStat:Dynamic, cell:TableCellElement, position:String) {
        var container:DivElement = Browser.document.createDivElement();
        container.classList.add('matchupChartLabel-$position');

        var span:SpanElement = Browser.document.createSpanElement();
        span.classList.add('matchupChartLabelRotate-$position');

        var pokemonTypes:Array<String> = pokemonStat.types;

        for (pokemonType in pokemonTypes) {
            var typeIcon:SpanElement = Browser.document.createSpanElement();
            typeIcon.classList.add('pokemonType-$pokemonType');
            typeIcon.classList.add("miniPokemonTypeIcon");
            typeIcon.textContent = " ";
            span.appendChild(typeIcon);
        }

        var labelText:SpanElement = Browser.document.createSpanElement();
        labelText.textContent = pokemonStat.name;
        span.appendChild(labelText);

        container.appendChild(span);
        cell.appendChild(container);
    }

    function processMoveLabelCell(moveStats:Dynamic, cell:TableCellElement, position:String) {
        var container:DivElement = Browser.document.createDivElement();
        container.classList.add('matchupChartMoveLabel-$position');

        var span:SpanElement = Browser.document.createSpanElement();
        span.classList.add('matchupChartMoveLabelRotate-$position');

        var typeIcon:SpanElement = Browser.document.createSpanElement();
        typeIcon.classList.add('pokemonType-${moveStats.move_type}');
        typeIcon.classList.add("miniPokemonTypeIcon");
        typeIcon.textContent = " ";
        span.appendChild(typeIcon);

        var moveLabelText:SpanElement = Browser.document.createSpanElement();
        moveLabelText.textContent = moveStats.name;
        span.appendChild(moveLabelText);

        span.appendChild(Browser.document.createBRElement());

        var extraInfo:SpanElement = Browser.document.createSpanElement();
        extraInfo.innerHTML = '${moveStats.power}<small>pwr</small>';
        extraInfo.classList.add("dimLabel");
        span.appendChild(extraInfo);

        container.appendChild(span);
        cell.appendChild(container);
    }

    function renderDividerCell(rowElement:TableRowElement, ?classSuffix:String):TableCellElement {
        var dividerCell = cast(rowElement.insertCell(-1), TableCellElement);
        dividerCell.classList.add("matchupChartDividerCell");

        if (classSuffix != null) {
            dividerCell.classList.add('matchupChartDividerCell-$classSuffix');
        }

        return dividerCell;
    }

    function processCellEfficacy(cell:TableCellElement, userMoveStat:Dynamic, userPokemonStat:Dynamic, foePokemonStat:Dynamic) {
        if (userMoveStat.power == "--") {
            return;
        }

        var userMoveType:String = userMoveStat.move_type;
        var userTypes:Array<String> = userPokemonStat.types;
        var foeTypes:Array<String> = foePokemonStat.types;

        var factor = descriptionsDataset.getTypeEfficacy(userMoveType, foeTypes[0], foeTypes[1]);
        var factorString;

        switch (factor) {
            case 0:
                factorString = "0";
            case 25:
                factorString = "¼";
            case 50:
                factorString = "½";
            case 100:
                factorString = "1";
            case 200:
                factorString = "2";
            case 400:
                factorString = "4";
            default:
                factorString = "Err";
        }

        var userAttack;
        var foeDefense;
        var userBasePower = userMoveStat.power;

        if (userMoveStat.damage_category == "physical") {
            userAttack = userPokemonStat.attack;
        } else {
            userAttack = userPokemonStat.special_attack;
        }

        if (userMoveStat.damage_category == "physical") {
            foeDefense = foePokemonStat.defense;
        } else {
            foeDefense = foePokemonStat.special_defense;
        }

        var stab = userTypes.indexOf(userMoveType) != -1;

        var estimatedDamage = Formula.computeDamage(userAttack, foeDefense, userBasePower, stab, factor);

        if (userMoveStat.max_hits != null) {
            estimatedDamage *= userMoveStat.max_hits;
        }

        var estimatedPercentage = Std.int(estimatedDamage / foePokemonStat.hp * 100);

        cell.innerHTML = '<span class="damageEfficacy-$factor">×$factorString</span>
            <br>
            <span>$estimatedPercentage%</span>';
    }
}

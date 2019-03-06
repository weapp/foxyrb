require "./lib/foxy"


p Foxy::Html.new("<div><table>Lorem ipsum dolor <tr class=\"needle\"><td>sit</td></table></div>").find(cls: "needle")

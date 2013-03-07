Zepto ->
  if localStorage.getItem("naubino_hiscore")?
    scores = JSON.parse localStorage.getItem("naubino_hiscore")
    console.log scores

  head = _.template "<tr><th> <%= name %> </th> <th> <%= points%> </th></tr>"

  line = _.template "<tr>
    <td> <%= name %> </td>
    <td> <%= points%> points  </td>
    <td> level <%= level %> </td>
    </tr>"


  scores = _(scores).sortBy (s)-> -s.points


  #$("#highscore_table").append head {name: "Name", points: "Points"}

  for score in scores
    $(".highscore_table").append line score

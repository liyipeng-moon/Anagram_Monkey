function set_font(FontSize)
set(gca,'color','w')
hText = findall(gca, 'Type', 'text');
for i = 1:length(hText)
    set(hText(i), 'FontName', 'Arial');
    set(hText(i), 'FontSize', FontSize);
end
ax = gca;
ax.FontName = 'Arial';
ax.FontSize = FontSize;
box off